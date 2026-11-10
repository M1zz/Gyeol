#!/bin/sh
# 맥 앱 배포 전 게이트 — 여기서 실패하면 DeployBar 가 아카이브를 만들지 않는다.
#   1) 공용 로직 시험 + iOS 빌드 (레포 최상단의 scripts/predeploy.sh — 두 앱이 같은 Shared/ · Yeoul/Store 를 쓴다)
#   2) 맥 앱 빌드
set -e
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
sh scripts/predeploy.sh
echo "🔨 빌드 확인 (YeoulMac)"
xcodebuild -project YeoulMac/YeoulMac.xcodeproj -scheme YeoulMac -configuration Debug \
  -destination 'platform=macOS' -allowProvisioningUpdates -quiet build
echo "✅ 맥 게이트 통과"
