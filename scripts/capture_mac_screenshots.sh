#!/bin/sh
# 맥 앱 스토어 스크린샷을 언어마다 찍는다 → YeoulMac/docs/screenshots/raw/<언어>/ , marketing/<언어>/ (2560×1600)
#
# 사용법:
#   PHOTOS=<IMG_0001.JPG … IMG_0006.HEIC 가 든 폴더> sh scripts/capture_mac_screenshots.sh <앱(.app, Debug)> [언어 ...]
#
# - 앱은 Debug 빌드여야 한다(예시 기록을 넣는 ScreenshotDemo 는 DEBUG 에만 있다). 스크린샷 모드는 메모리
#   저장소만 쓰므로 이 Mac 의 진짜 기록과 iCloud 는 건드리지 않는다 (→ YeoulMac/Sources/YeoulMacApp.swift).
# - 앱은 샌드박스 안이라 예시 기록 JSON 과 사진 폴더를 못 읽는다. 스크린샷용 빌드만 Config/macOS.entitlements 에
#   com.apple.security.temporary-exception.files.absolute-path.read-only 로 두 폴더를 더한 권한 파일로 만든다:
#     xcodebuild -project YeoulMac/YeoulMac.xcodeproj -scheme YeoulMac -configuration Debug \
#       -derivedDataPath build/mac-shots -allowProvisioningUpdates CODE_SIGN_ENTITLEMENTS=<그 권한 파일> build
# - 앱을 뒤에서 띄우고(open -g) 창 번호로 찍는다. 쓰던 창의 포커스를 뺏지 않는다.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$1"; shift
LANGS="$*"
[ -n "$LANGS" ] || LANGS="ko en en-GB zh-Hans zh-Hant ja ru es de fr it pt-BR th vi cs da el fi id nb nl pl sv tr"
PHOTOS="${PHOTOS:?PHOTOS=<IMG_0001.JPG … IMG_0006.HEIC 가 든 폴더> 를 지정}"
DEMO="$ROOT/scripts/screenshot_demo"
OUT="$ROOT/YeoulMac/docs/screenshots"
WAIT="${WAIT:-4}"
WINID="${TMPDIR:-/tmp}/yeoul_mac_window_id"
[ -x "$WINID" ] || swiftc -O "$ROOT/scripts/mac_window_id.swift" -o "$WINID"

locale_of() {
  case "$1" in
    ko) echo ko_KR ;; en) echo en_US ;; en-GB) echo en_GB ;; zh-Hans) echo zh_CN ;; zh-Hant) echo zh_TW ;;
    ja) echo ja_JP ;; ru) echo ru_RU ;; es) echo es_ES ;; de) echo de_DE ;; fr) echo fr_FR ;; it) echo it_IT ;;
    pt-BR) echo pt_BR ;; th) echo th_TH@calendar=gregorian ;; vi) echo vi_VN ;; cs) echo cs_CZ ;; da) echo da_DK ;;
    el) echo el_GR ;; fi) echo fi_FI ;; id) echo id_ID ;; nb) echo nb_NO ;; nl) echo nl_NL ;; pl) echo pl_PL ;;
    sv) echo sv_SE ;; tr) echo tr_TR ;; *) echo "$1" ;;
  esac
}

# 실행 파일 이름으로 찾는다 (한글 경로는 정규화가 달라 pgrep 이 놓친다)
running() { pgrep -f "MacOS/Yeoul .*-demoSeed" | head -1; }

shot() { # 언어 파일이름 [앱 인자...]
  lang="$1"; name="$2"; shift 2
  old="$(running)"; [ -z "$old" ] || { kill "$old"; sleep 0.5; }
  open -g -n "$APP" --args -localOnly -AppleLanguages "($lang)" -AppleLocale "$(locale_of "$lang")" \
    -demoSeed "$DEMO/$lang.json" -demoPhotos "$PHOTOS" "$@"
  sleep 2.5
  # 뒤에서 띄운 앱은 창을 만들지 않는다. reopen 은 앞으로 가져오지 않고 창만 만든다.
  osascript -e 'tell application id "com.leeo.yeoul" to reopen' >/dev/null 2>&1
  sleep 1.5
  pid="$(running)"
  osascript -e "tell application \"System Events\" to tell (first process whose unix id is $pid)
    set position of window 1 to {160, 50}
    set size of window 1 to {1280, 800}
  end tell" >/dev/null
  sleep "$WAIT"
  mkdir -p "$OUT/raw/$lang" "$OUT/marketing/$lang"
  screencapture -x -o -l "$("$WINID" "$pid")" "$OUT/raw/$lang/$name"
  kill "$pid"
  # 제출본: 창 모서리의 투명을 창 바탕색으로 메운다 (스토어는 투명이 있는 그림을 받지 않는다)
  python3 - "$OUT/raw/$lang/$name" "$OUT/marketing/$lang/$name" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGBA")
assert im.size == (2560, 1600), im.size
flat = Image.new("RGB", im.size, (255, 255, 255))
left = Image.new("RGB", (im.size[0] // 2, im.size[1]), im.getpixel((40, im.size[1] // 2))[:3])
flat.paste(left, (0, 0))   # 왼쪽 모서리는 사이드바 색, 오른쪽은 흰 바탕
flat.paste(im, (0, 0), im)
flat.save(sys.argv[2])
PY
  echo "  $lang/$name"
}

for lang in $LANGS; do
  echo "▸ $lang"
  shot "$lang" 01-trip.png   -demoTimeline 2
  shot "$lang" 02-expand.png -demoTimeline 2 -demoExpand 5
  shot "$lang" 03-tag.png    -demoTimeline 4
done
