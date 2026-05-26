#!/usr/bin/env bash
#******************************************************************************
#
#   build-ios-xcframework.sh - Build raylib static xcframework for iOS
#
#   Slices: ios-arm64 (device), ios-arm64-sim, ios-x86_64-sim (simulator)
#
#   Usage: ./build-ios-xcframework.sh [output_dir]
#     Default output: ../../raylib.xcframework  (project root)
#
#   Prerequisites: macOS + Xcode 15+
#   Run from: projects/scripts/ (or adjust RAYLIB_SRC below)
#
#   NOTE: ANGLE (libEGL, libGLESv2) NOT bundled. Link separately.
#   See raylib-iOS/deps/ANGLE/ for ANGLE xcframeworks.
#
#   License: zlib/libpng
#
#******************************************************************************

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAYLIB_SRC="$(cd "$SCRIPT_DIR/../../src" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${1:-$PROJECT_ROOT/raylib.xcframework}"

DEPLOYMENT_TARGET=15.6

SOURCES=(raudio.c rcore.c rmodels.c rshapes.c rtext.c rtextures.c)
PUBLIC_HEADERS=(raylib.h raymath.h rlgl.h rcamera.h)

# ── Build one slice ─────────────────────────────────────────────────

build_slice() {
    local sdk="$1"          # iphoneos | iphonesimulator
    local arch="$2"         # arm64 | x86_64
    local slice_id="$3"     # ios-arm64 | ios-arm64-sim | ios-x86_64-sim
    local outdir="$4"

    echo "  [$slice_id] building $arch ($sdk)..."

    local sdk_root; sdk_root=$(xcrun --sdk "$sdk" --show-sdk-path)
    local objdir="$outdir/$slice_id/obj"
    mkdir -p "$objdir"

    local minver_flag
    [[ "$sdk" == "iphoneos" ]] && minver_flag="-miphoneos-version-min" || minver_flag="-miphonesimulator-version-min"

    # Map slice_id -> ANGLE variant folder
    local angle_variant
    case "$slice_id" in
        ios-arm64)       angle_variant="ios-arm64" ;;
        ios-arm64-sim)   angle_variant="ios-arm64_x86_64-simulator" ;;
        ios-x86_64-sim)  angle_variant="ios-arm64_x86_64-simulator" ;;
        *)               angle_variant="ios-arm64" ;;
    esac
    local angle_gles_hdrs="$PROJECT_ROOT/deps/ANGLE/libGLESv2.xcframework/$angle_variant/libGLESv2.framework/Headers"
    local angle_egl_hdrs="$PROJECT_ROOT/deps/ANGLE/libEGL.xcframework/$angle_variant/libEGL.framework/Headers"

    # Staging dir with proper naming so #include <libGLESv2/GLES/...> resolves
    local inc_stage="$outdir/include_staging/$slice_id"
    mkdir -p "$inc_stage"
    ln -sfn "$angle_gles_hdrs" "$inc_stage/libGLESv2"
    ln -sfn "$angle_egl_hdrs" "$inc_stage/libEGL"

    local flags=(
        -arch "$arch"
        -std=c17
        -fobjc-arc
        -isysroot "$sdk_root"
        "$minver_flag=$DEPLOYMENT_TARGET"
        -DPLATFORM_IOS
        -DGRAPHICS_API_OPENGL_ES3
        -DGL_GLEXT_PROTOTYPES
        -I"$RAYLIB_SRC"
        -I"$inc_stage"
        -fmodules
        -O2
        -DNDEBUG
        -Wno-unused-parameter
        -Wno-pointer-sign
        -Wno-int-conversion
        -include "$angle_gles_hdrs/GLES/gl.h"
    )

    for src in "${SOURCES[@]}"; do
        echo "    CC  $src"
        local lang_flag=""
        # raudio.c: miniaudio.h pulls in AVFoundation (ObjC) on iOS
        # rcore.c: includes rcore_ios.c which pulls in UIKit (ObjC)
        [[ "$src" == "raudio.c" || "$src" == "rcore.c" ]] && lang_flag="-x objective-c"
        xcrun clang "${flags[@]}" $lang_flag -c "$RAYLIB_SRC/$src" -o "$objdir/${src%.c}.o"
    done

    local fwdir="$outdir/$slice_id/raylib.framework"
    mkdir -p "$fwdir/Headers"

    xcrun ar rcs "$fwdir/raylib" "$objdir"/*.o
    rm -rf "$objdir"

    for hdr in "${PUBLIC_HEADERS[@]}"; do
        cp "$RAYLIB_SRC/$hdr" "$fwdir/Headers/$hdr"
    done

    cat > "$fwdir/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>raylib</string>
    <key>CFBundleIdentifier</key><string>com.raylib.framework</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>raylib</string>
    <key>CFBundlePackageType</key><string>FMWK</string>
    <key>CFBundleShortVersionString</key><string>6.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>MinimumOSVersion</key><string>$DEPLOYMENT_TARGET</string>
</dict>
</plist>
EOF

    echo "  [$slice_id] done"
}

# ── Create XCFramework ──────────────────────────────────────────────

echo "=== raylib iOS XCFramework ==="
echo "  src:   $RAYLIB_SRC"
echo "  out:   $OUTPUT_DIR"
echo "  minOS: $DEPLOYMENT_TARGET"
echo ""

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

build_slice iphoneos       arm64   ios-arm64       "$BUILD_DIR"
build_slice iphonesimulator arm64  ios-arm64-sim   "$BUILD_DIR"
build_slice iphonesimulator x86_64 ios-x86_64-sim  "$BUILD_DIR"

echo ""
echo "=== Creating fat simulator framework ==="
SIM_FAT_DIR="$BUILD_DIR/ios-sim-fat/raylib.framework"
mkdir -p "$SIM_FAT_DIR/Headers"

# Merge simulator binaries into a universal (fat) binary
xcrun lipo -create \
    "$BUILD_DIR/ios-arm64-sim/raylib.framework/raylib" \
    "$BUILD_DIR/ios-x86_64-sim/raylib.framework/raylib" \
    -output "$SIM_FAT_DIR/raylib"

# Copy headers from either sim slice (identical)
cp -r "$BUILD_DIR/ios-arm64-sim/raylib.framework/Headers/" "$SIM_FAT_DIR/Headers/"
cp "$BUILD_DIR/ios-arm64-sim/raylib.framework/Info.plist" "$SIM_FAT_DIR/Info.plist"

echo ""
echo "=== Creating XCFramework ==="
rm -rf "$OUTPUT_DIR"

xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/ios-arm64/raylib.framework" \
    -framework "$SIM_FAT_DIR" \
    -output "$OUTPUT_DIR"

echo ""
echo "=== Done ==="
echo "  $OUTPUT_DIR"
