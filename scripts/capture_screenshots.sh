#!/bin/sh
# 스토어 스크린샷 원본을 언어마다 시뮬레이터로 찍는다 → docs/screenshots/raw/<언어>/ , raw/creative/<언어>/
# 그다음 make_marketing_screenshots.py · make_creative_assets.py 가 제출용 그림을 만든다.
#
# 사용법:
#   sh scripts/capture_screenshots.sh <iPhone 시뮬레이터 UDID|-> <iPad 시뮬레이터 UDID|-> <앱(.app, Debug)> [언어 ...]
#   - 기기 하나를 - 로 두면 그 기기는 건너뛴다(시뮬레이터를 한 번에 하나만 켜 두려면 두 번 나눠 돌린다).
#   - 시뮬레이터는 미리 켜 둔다(아이폰 6.9" 1320x2868, 아이패드 13" 2064x2752).
#   - 앱은 Debug 빌드여야 한다(예시 기록을 넣는 ScreenshotDemo 는 DEBUG 에만 있다).
#   - 사진은 시뮬레이터 기본 사진(IMG_0001~0006)을 PHOTOS 폴더에서 읽는다.
#
# 화면 속 기록은 scripts/screenshot_demo/<언어>.json — 그 언어로 쓴 예시 기록이다.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PHONE="$1"; PAD="$2"; APP="$3"; shift 3
LANGS="$*"
[ -n "$LANGS" ] || LANGS="ko en en-GB zh-Hans zh-Hant ja ru es de fr it pt-BR th vi cs da el fi id nb nl pl sv tr"
PHOTOS="${PHOTOS:?PHOTOS=<IMG_0001.JPG … IMG_0006.HEIC 가 든 폴더> 를 지정}"
BUNDLE="com.leeo.yeoul"
DEMO="$ROOT/scripts/screenshot_demo"
WAIT="${WAIT:-6}"

# 언어 → AppleLocale (지역이 날짜 표기를 정한다: en-GB 는 dd/mm)
locale_of() {
  case "$1" in
    ko) echo ko_KR ;; en) echo en_US ;; en-GB) echo en_GB ;; zh-Hans) echo zh_CN ;; zh-Hant) echo zh_TW ;;
    ja) echo ja_JP ;; ru) echo ru_RU ;; es) echo es_ES ;; de) echo de_DE ;; fr) echo fr_FR ;; it) echo it_IT ;;
    pt-BR) echo pt_BR ;; th) echo th_TH@calendar=gregorian ;; vi) echo vi_VN ;; cs) echo cs_CZ ;; da) echo da_DK ;;
    el) echo el_GR ;; fi) echo fi_FI ;; id) echo id_ID ;; nb) echo nb_NO ;; nl) echo nl_NL ;; pl) echo pl_PL ;;
    sv) echo sv_SE ;; tr) echo tr_TR ;; *) echo "$1" ;;
  esac
}

# 시간 제한을 둔 실행 (시뮬레이터가 멈춰도 스크립트가 같이 멈추지 않게)
t() { perl -e 'alarm shift; exec @ARGV' "$@"; }

shot() { # 기기 언어 출력파일 [앱 인자...]
  dev="$1"; lang="$2"; out="$3"; shift 3
  loc="$(locale_of "$lang")"
  t 30 xcrun simctl terminate "$dev" "$BUNDLE" >/dev/null 2>&1 || true
  t 60 xcrun simctl launch "$dev" "$BUNDLE" -localOnly \
      -AppleLanguages "($lang)" -AppleLocale "$loc" \
      -hasSeenOnboarding YES \
      -demoSeed "$DEMO/$lang.json" -demoPhotos "$PHOTOS" "$@" >/dev/null
  sleep "$WAIT"
  mkdir -p "$(dirname "$out")"
  t 60 xcrun simctl io "$dev" screenshot "$out" >/dev/null 2>&1
  echo "  $out"
}

prep() { # 기기
  t 60 xcrun simctl install "$1" "$APP"
  t 30 xcrun simctl status_bar "$1" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
      --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
}

# 아이패드 상태 막대에는 날짜와 앱 이름이 기기 언어로 찍힌다 — 기기 언어를 바꾸고 다시 켠다.
set_device_language() { # 기기 언어
  t 30 xcrun simctl spawn "$1" defaults write .GlobalPreferences AppleLanguages -array "$2"
  t 30 xcrun simctl spawn "$1" defaults write .GlobalPreferences AppleLocale -string "$(locale_of "$2")"
  t 120 xcrun simctl shutdown "$1" >/dev/null 2>&1 || true
  t 180 xcrun simctl boot "$1"
  t 300 xcrun simctl bootstatus "$1" -b >/dev/null 2>&1 || true
  t 30 xcrun simctl status_bar "$1" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
      --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true
  sleep 5
}

tag_of() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['timelines'][2]['events'][5]['tags'][0])" "$DEMO/$1.json"; }

[ "$PHONE" = "-" ] || prep "$PHONE"
[ "$PAD" = "-" ] || prep "$PAD"

for lang in $LANGS; do
  echo "▸ $lang"
  RAW="$ROOT/docs/screenshots/raw/$lang"
  CRE="$ROOT/docs/screenshots/raw/creative/$lang"
  TAG="$(tag_of "$lang")"
  if [ "$PHONE" != "-" ]; then
  shot "$PHONE" "$lang" "$RAW/01-trip.png"    -demoScreen trip -demoTimeline 2
  shot "$PHONE" "$lang" "$RAW/02-iceland.png" -demoScreen trip -demoTimeline 2 -demoScroll 4 -demoAnchor 0.5
  shot "$PHONE" "$lang" "$RAW/03-expand.png"  -demoScreen trip -demoTimeline 2 -demoExpand 5
  shot "$PHONE" "$lang" "$RAW/04-tag.png"     -demoScreen tag -demoTag "$TAG"
  shot "$PHONE" "$lang" "$RAW/05-editor.png"  -demoScreen trip -demoTimeline 2 -demoExpand 5 -demoEdit 5
  shot "$PHONE" "$lang" "$CRE/01-timeline.png" -demoScreen trip -demoTimeline 0
  shot "$PHONE" "$lang" "$CRE/02-list.png"     -demoScreen list
  fi
  if [ "$PAD" != "-" ]; then
    set_device_language "$PAD" "$lang"
    shot "$PAD" "$lang" "$RAW/ipad-01-trip.png"   -demoScreen trip -demoTimeline 2
    shot "$PAD" "$lang" "$RAW/ipad-02-expand.png" -demoScreen trip -demoTimeline 2 -demoExpand 5
    shot "$PAD" "$lang" "$RAW/ipad-03-tag.png"    -demoScreen tag -demoTag "$TAG"
    shot "$PAD" "$lang" "$RAW/ipad-04-editor.png" -demoScreen tag -demoTag "$TAG" -demoExpand 2 -demoEdit 2
  fi
done
