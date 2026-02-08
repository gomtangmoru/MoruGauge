#!/bin/bash
set -e

echo "🔨 morugauge 빌드 중..."

# Swift Package Manager로 빌드
swift build -c release 2>&1

# .app 번들 생성
APP_NAME="morugauge"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app/Contents"

echo "📦 .app 번들 생성 중..."

# 기존 빌드 정리
rm -rf "$BUILD_DIR/$APP_NAME.app"

# 디렉토리 구조 생성
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources/Locales"

# 바이너리 복사
cp ".build/release/$APP_NAME" "$APP_DIR/MacOS/"

# Info.plist 복사
cp "Resources/Info.plist" "$APP_DIR/"

# Locales 파일 복사
cp Resources/Locales/*.json "$APP_DIR/Resources/Locales/"

# 앱 아이콘 복사
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$APP_DIR/Resources/"
    echo "🎨 앱 아이콘 적용 완료"
fi

echo ""
echo "✅ 빌드 완료!"
echo "📍 위치: $BUILD_DIR/$APP_NAME.app"
echo ""
echo "🚀 실행하려면:"
echo "   open $BUILD_DIR/$APP_NAME.app"
echo ""
echo "🌐 번역 파일 위치:"
echo "   ~/Library/Application Support/morugauge/Locales/"
echo "   (처음 실행 시 자동 생성됩니다)"
echo ""
echo "🛑 종료하려면:"
echo "   메뉴바 아이콘 클릭 → Quit"
echo "   또는: pkill -f $APP_NAME"
