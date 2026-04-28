#!/usr/bin/env bash
# build-atmosphere-lampa.sh — build the ATMOSphere-Lampa APK and copy it
# into the parent ATMOSphere prebuilt-apps tree.
#
# Usage:
#     bash device/rockchip/atmosphere/lampa/build-atmosphere-lampa.sh
#
# Output:
#     device/rockchip/rk3588/prebuilt_apps/atmosphere-lampa.apk
#
# Signing: debug-quality keystore generated on-demand. AOSP re-signs
# with the platform key at image-assembly time via
# LOCAL_CERTIFICATE := platform in prebuilt_apps/Android.mk.
#
# The Lampa fork's app/build.gradle has a `signingConfigs.release` block
# that reads from `app/keystore/keystore_config` Properties file OR env
# vars (KEYSTORE_FILE / KEYSTORE_PASSWORD / RELEASE_SIGN_KEY_ALIAS /
# RELEASE_SIGN_KEY_PASSWORD). We use the env-var path with the standard
# Android debug keystore.
#
# JDK: gradle 8.x + AGP 8.x require Java 21 (or 17 for some flavours).
# Mirror torrserve's picker (try jdk21 first, fall back to jdk17).
#
# Fails loudly so scripts/build.sh halts early on real errors.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

cd "$SCRIPT_DIR"

echo "[ATMOSphere-Lampa] build-atmosphere-lampa.sh"
echo "  script dir: $SCRIPT_DIR"
echo "  parent:     $PARENT_ROOT"

for gw in ./gradlew; do
    [ -f "$gw" ] && chmod +x "$gw" 2>/dev/null || true
done

# Lampa uses gradle 7.5.1 which requires Java 17 (or 11) — Java 21
# class file version 65 is rejected. Pick JDK 17 first.
_pick_jdk() {
    for cand in \
        "$PARENT_ROOT/prebuilts/jdk/jdk17/linux-x86" \
        "$PARENT_ROOT/prebuilts/jdk/jdk17" \
        /usr/lib/jvm/java-17-openjdk \
        /usr/lib/jvm/java-17-openjdk-*.x86_64 \
        /usr/lib/jvm/jre-17-openjdk \
        "$PARENT_ROOT/prebuilts/jdk/jdk21/linux-x86" \
        "$PARENT_ROOT/prebuilts/jdk/jdk21" \
        /usr/lib/jvm/java-21-openjdk \
        /usr/lib/jvm/java-21-openjdk-*.x86_64; do
        for actual in $cand; do
            if [ -x "$actual/bin/java" ]; then
                export JAVA_HOME="$actual"
                return 0
            fi
        done
    done
    echo "[ATMOSphere-Lampa] WARNING: no JDK 17/21 found — gradle may fail on older Java"
    return 1
}
_pick_jdk || true
if [ -n "${JAVA_HOME:-}" ]; then
    echo "[ATMOSphere-Lampa] JAVA_HOME=$JAVA_HOME"
    "$JAVA_HOME/bin/java" -version 2>&1 | head -1
fi

# Provide debug keystore via env vars (Lampa's signingConfigs.release
# falls back to env when app/keystore/keystore_config is missing — see
# app/build.gradle).
_DEBUG_KS="$HOME/.android/debug.keystore"
if [ ! -f "$_DEBUG_KS" ]; then
    echo "[ATMOSphere-Lampa] creating $_DEBUG_KS (fresh machine; standard debug passwords)"
    mkdir -p "$HOME/.android"
    keytool -genkey -v \
        -keystore "$_DEBUG_KS" \
        -storepass android -keypass android \
        -alias androiddebugkey \
        -dname "CN=Android Debug,O=Android,C=US" \
        -keyalg RSA -keysize 2048 -validity 10000 2>&1 | tail -2
fi
export KEYSTORE_FILE="$_DEBUG_KS"
export KEYSTORE_PASSWORD="android"
export RELEASE_SIGN_KEY_ALIAS="androiddebugkey"
export RELEASE_SIGN_KEY_PASSWORD="android"

# Make sure the fork's `keystore/keystore_config` does NOT exist so the
# build.gradle fallback to env vars activates.
rm -f app/keystore/keystore_config 2>/dev/null || true

echo "[ATMOSphere-Lampa] running: ./gradlew :app:assembleFullRelease"
# Lampa fork has flavor dimensions: full / lite / ruStore. The 'full'
# flavor is the standard build with all features enabled (matches
# upstream's recommended distribution). 'lite' strips features;
# 'ruStore' is for the Russian Play Store. Build only 'full' to
# avoid wasting compile time on unused flavors.
bash ./gradlew :app:assembleFullRelease --no-daemon --console=plain

# Find the release APK — flavor 'full' lands in app/build/outputs/apk/full/release/
APK_PATH=$(find app/build/outputs/apk/full/release -type f -name '*.apk' 2>/dev/null | head -1)
if [ -z "${APK_PATH:-}" ] || [ ! -f "$APK_PATH" ]; then
    echo "[ATMOSphere-Lampa] ERROR: gradle reported success but no APK found under app/build/outputs/apk/full/release/"
    ls -la app/build/outputs/apk/full/release/ 2>&1 | head -10
    # Fall back: look anywhere for an APK in case Lampa upstream renamed dirs.
    APK_PATH=$(find app/build/outputs/apk -type f -name 'app-full-release*.apk' 2>/dev/null | head -1)
    if [ -z "${APK_PATH:-}" ]; then
        exit 2
    fi
    echo "[ATMOSphere-Lampa] fallback found: $APK_PATH"
fi
echo "[ATMOSphere-Lampa] built APK: $APK_PATH"

DEST="$PARENT_ROOT/device/rockchip/rk3588/prebuilt_apps/atmosphere-lampa.apk"
cp -f "$APK_PATH" "$DEST"
echo "[ATMOSphere-Lampa] copied to: $DEST"
ls -lh "$DEST"

echo "[ATMOSphere-Lampa] done. scripts/build.sh will pick this APK"
echo "  up via device/rockchip/rk3588/prebuilt_apps/Android.mk and re-"
echo "  sign with the platform key at system-image assembly."
