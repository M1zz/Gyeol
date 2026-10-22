#!/usr/bin/env python3
"""App Store 마케팅 스크린샷: 시뮬레이터 원본 캡처 + 헤드라인 → HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_marketing_screenshots.py [언어 ...]   (없으면 전부)

  원본  docs/screenshots/raw/<언어>/NN-….png         (iPhone 6.9" 시뮬레이터 캡처 1320x2868, 올라가지 않는다)
  제출  docs/screenshots/marketing/<스토어 로케일>/NN-….png   (1242x2688, DeployBar 가 그대로 올린다)

파일 이름 순서가 스토어에 보이는 순서다. 다음 릴리즈에는 원본만 다시 찍고 이 스크립트를 다시 돌린다.
"""
import subprocess, sys, pathlib, tempfile, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1242, 2688   # 이 계정의 iPhone 제출 규격

# ── 앱마다 고치는 곳 ──────────────────────────────────────────────
# 앱 언어 → App Store 로케일 (스토어 폴더 이름)
STORE = {"ko": "ko", "en": "en", "en-GB": "en-GB", "zh-Hans": "zh-Hans"}
# 바탕 · 포인트 색 (헤더·검색 결과 그림과 맞춘다)
BG, ACCENT, INK, SUB = "#F4F1EA", "#2E6B5E", "#1D2A27", "#6B6A63"
# 언어 → [(원본 파일, 레이아웃, 헤드라인, 서브카피)]
SHOTS = {
    "ko": [
        ("01-trip.png",    "hero-bleed",  "흐른 시간만큼<br>벌어지는 타임라인", "사흘과 닷새는 3대 5로, 긴 공백은 점선으로"),
        ("02-iceland.png", "left-text",   "사진과 함께<br>그날을 남겨요", "카드 디자인 네 가지 중에서 골라요"),
        ("03-expand.png",  "text-bottom", "누르면 그 자리에서 펼쳐져요", "사진과 이야기를 한눈에"),
        ("04-tag.png",     "flat-rotate", "해시태그로<br>다시 엮기", "흩어진 기록이 새 타임라인이 돼요"),
        ("05-editor.png",  "dark",        "카드 디자인도<br>사건마다 골라요", "날짜, 내용, 태그까지 한 화면에서"),
    ],
    "en": [
        ("01-trip.png", "hero-bleed", "Time stretches<br>the way it flowed", "Three days and five days sit 3:5 apart; long gaps fold into dots"),
        ("02-iceland.png", "left-text", "Keep the day<br>with its photos", "Pick from four card designs"),
        ("03-expand.png", "text-bottom", "Tap to open it right there", "Photos and stories at a glance"),
        ("04-tag.png", "flat-rotate", "Weave events<br>together with hashtags", "Scattered records become a new timeline"),
        ("05-editor.png", "dark", "Pick a card design<br>for each event", "Date, notes and tags on one screen"),
    ],
    "en-GB": [
        ("01-trip.png", "hero-bleed", "Time stretches<br>the way it flowed", "Three days and five days sit 3:5 apart; long gaps fold into dots"),
        ("02-iceland.png", "left-text", "Keep the day<br>with its photos", "Pick from four card designs"),
        ("03-expand.png", "text-bottom", "Tap to open it right there", "Photos and stories at a glance"),
        ("04-tag.png", "flat-rotate", "Weave events<br>together with hashtags", "Scattered records become a new timeline"),
        ("05-editor.png", "dark", "Pick a card design<br>for each event", "Date, notes and tags on one screen"),
    ],
    "zh-Hans": [
        ("01-trip.png", "hero-bleed", "按流逝的时间<br>拉开的时间线", "三天和五天以 3:5 拉开，长空白折成虚线"),
        ("02-iceland.png", "left-text", "连同照片<br>留下那一天", "四种卡片样式任你挑选"),
        ("03-expand.png", "text-bottom", "轻点即可就地展开", "照片和故事一目了然"),
        ("04-tag.png", "flat-rotate", "用话题标签<br>重新串联", "分散的记录变成一条新时间线"),
        ("05-editor.png", "dark", "卡片样式<br>每个事件自己选", "日期、内容、标签都在一个页面"),
    ],
}
# 아이패드 13" (2064x2752). 원본은 raw/<언어>/ipad-*.png
IW, IH = 2064, 2752
SHOTS_IPAD = {
    "ko": [
        ("ipad-01-trip.png",   "흐른 시간만큼 벌어지는 타임라인", "사흘과 닷새는 3대 5로, 긴 공백은 점선으로"),
        ("ipad-02-expand.png", "누르면 그 자리에서 펼쳐져요", "사진과 이야기를 한눈에"),
        ("ipad-03-tag.png",    "해시태그로 다시 엮기", "흩어진 기록이 새 타임라인이 돼요"),
        ("ipad-04-editor.png", "그날의 사진과 이야기를 남겨요", "날짜, 내용, 태그, 카드 디자인까지"),
    ],
    "en": [
        ("ipad-01-trip.png", "A timeline that stretches with time", "Three days and five days sit 3:5 apart; long gaps fold into dots"),
        ("ipad-02-expand.png", "Tap to open it right there", "Photos and stories at a glance"),
        ("ipad-03-tag.png", "Weave events together with hashtags", "Scattered records become a new timeline"),
        ("ipad-04-editor.png", "Keep the day’s photos and story", "Date, notes, tags and card design"),
    ],
    "en-GB": [
        ("ipad-01-trip.png", "A timeline that stretches with time", "Three days and five days sit 3:5 apart; long gaps fold into dots"),
        ("ipad-02-expand.png", "Tap to open it right there", "Photos and stories at a glance"),
        ("ipad-03-tag.png", "Weave events together with hashtags", "Scattered records become a new timeline"),
        ("ipad-04-editor.png", "Keep the day’s photos and story", "Date, notes, tags and card design"),
    ],
    "zh-Hans": [
        ("ipad-01-trip.png", "按流逝的时间拉开的时间线", "三天和五天以 3:5 拉开，长空白折成虚线"),
        ("ipad-02-expand.png", "轻点即可就地展开", "照片和故事一目了然"),
        ("ipad-03-tag.png", "用话题标签重新串联", "分散的记录变成一条新时间线"),
        ("ipad-04-editor.png", "留下那一天的照片和故事", "日期、内容、标签、卡片样式"),
    ],
}
IPAD_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{IW}px; height:{IH}px; overflow:hidden; }}
body {{ background:{BG}; position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", sans-serif; }}
.text {{ text-align:center; padding:230px 120px 0; }}
.dot {{ display:inline-block; width:30px; height:30px; border-radius:50%; background:{ACCENT}; margin-bottom:56px; }}
.headline {{ font-size:124px; font-weight:800; color:{INK}; letter-spacing:-0.03em; line-height:1.15; word-break:keep-all; }}
.sub {{ font-size:60px; font-weight:500; color:{SUB}; margin-top:48px; word-break:keep-all; }}
.wrap {{ display:flex; justify-content:center; margin-top:130px; }}
.pad {{ width:1680px; background:#17171a; border-radius:96px; border:4px solid #3a3a3e; padding:36px;
  box-shadow: 50px 80px 120px rgba(20,40,90,.22), 16px 26px 46px rgba(0,0,0,.14); }}
.pad img {{ width:100%; display:block; border-radius:62px; }}
"""
# ─────────────────────────────────────────────────────────────────

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:{BG}; position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", "Hiragino Sans", "PingFang SC", sans-serif; }}
.headline {{ font-size:96px; font-weight:800; color:{INK}; letter-spacing:-0.03em; line-height:1.18; }}
.sub {{ font-size:48px; font-weight:500; color:{SUB}; letter-spacing:-0.01em; line-height:1.35; }}
:lang(ko) .headline, :lang(ko) .sub {{ word-break:keep-all; }}
.phone {{ background:#17171a; border-radius:112px; border:3px solid #3a3a3e; padding:24px;
  box-shadow: 50px 80px 120px rgba(20,40,90,.25), 16px 26px 46px rgba(0,0,0,.16); }}
.phone img {{ width:100%; display:block; border-radius:90px; }}
.dot {{ display:inline-block; width:22px; height:22px; border-radius:50%; background:{ACCENT}; margin-bottom:46px; }}
"""

LAYOUTS = {
    "hero-bleed": """
.text { text-align:center; padding:250px 80px 0; }
.sub { margin-top:44px; }
.wrap { display:flex; justify-content:center; margin-top:120px; }
.phone { width:960px; }
""",
    "left-text": """
.text { text-align:left; padding:260px 100px 0 110px; }
.sub { margin-top:44px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:290px; top:930px; }
.phone { width:820px; transform:rotateY(16deg) rotateX(2deg); }
""",
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:150px; }
.phone { width:840px; transform:rotateY(-10deg) rotateX(2deg); }
.text { text-align:center; padding:100px 80px 0; }
.sub { margin-top:40px; }
""",
    "flat-rotate": """
.text { text-align:center; padding:240px 80px 0; }
.sub { margin-top:44px; }
.wrap { position:absolute; left:120px; top:950px; }
.phone { width:960px; transform:rotate(-6deg); }
""",
    "dark": f"""
body {{ background:#131316; }}
.headline {{ color:#f5f5f7; }} .sub {{ color:#8a8a90; }}
.text {{ text-align:center; padding:250px 80px 0; }}
.sub {{ margin-top:44px; }}
.wrap {{ display:flex; justify-content:center; margin-top:120px; }}
.phone {{ width:900px; border-color:#48484e;
  box-shadow: 0 0 160px rgba(80,140,255,.22), 40px 70px 110px rgba(0,0,0,.55); }}
""",
}

TEXT = '<div class="text"><div class="dot"></div><div class="headline">{headline}</div><div class="sub">{sub}</div></div>'
PHONE = '<div class="wrap"><div class="phone"><img src="{img}"></div></div>'
HTML = '<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>{css}</style></head><body>{body}</body></html>'


def chrome_shot(html, png, tmp, size=(W, H)):
    """헤드리스 Chrome 으로 한 장 그린다.

    ⚠️ Chrome 은 그림을 다 쓰고도 끝나지 않고 멈추는 일이 잦다(여러 개가 동시에 돌 때 특히).
       그래서 끝나기를 기다리지 않고, 파일이 생겨 크기가 멈추면 프로세스를 닫는다.
    """
    png.unlink(missing_ok=True)
    proc = subprocess.Popen([CHROME, "--headless=new", f"--user-data-dir={tmp}/chrome", "--no-first-run",
                             "--disable-component-update", "--no-default-browser-check", "--disable-extensions",
                             f"--screenshot={png}", f"--window-size={size[0]},{size[1]}", "--force-device-scale-factor=1",
                             "--hide-scrollbars", "--allow-file-access-from-files", html.as_uri()],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    last, deadline = -1, time.time() + 180
    try:
        while time.time() < deadline:
            time.sleep(1)
            size = png.stat().st_size if png.exists() else -1
            if size > 10000 and size == last:
                return True
            last = size
            if proc.poll() is not None and size <= 0:
                return False
        return False
    finally:
        if proc.poll() is None:
            proc.kill()
        proc.wait()
        # 남은 도우미 프로세스도 이 프로필 것만 골라 닫는다
        subprocess.run(["pkill", "-f", f"{tmp}/chrome"], capture_output=True)


def render(lang):
    out_dir = OUT / STORE[lang]
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("*.png"):
        old.unlink()
    with tempfile.TemporaryDirectory() as tmp:
        for fname, layout, headline, sub in SHOTS[lang]:
            src = RAW / lang / fname
            assert src.exists(), f"원본이 없다: {src}"
            text = TEXT.format(headline=headline, sub=sub)
            phone = PHONE.format(img=src.as_uri())
            body = phone + text if layout == "text-bottom" else text + phone
            html = pathlib.Path(tmp) / f"{lang}-{fname}.html"
            html.write_text(HTML.format(lang=lang, css=BASE_CSS + LAYOUTS[layout], body=body), encoding="utf-8")
            png = out_dir / fname
            if not any(chrome_shot(html, png, tmp) for _ in range(3)):
                raise SystemExit(f"그리지 못했다: {png}")
            print("rendered", png.relative_to(ROOT))
        for fname, headline, sub in SHOTS_IPAD.get(lang, []):
            src = RAW / lang / fname
            assert src.exists(), f"원본이 없다: {src}"
            body = (TEXT.format(headline=headline, sub=sub) +
                    f'<div class="wrap"><div class="pad"><img src="{src.as_uri()}"></div></div>')
            html = pathlib.Path(tmp) / f"{lang}-{fname}.html"
            html.write_text(HTML.format(lang=lang, css=IPAD_CSS, body=body), encoding="utf-8")
            png = out_dir / fname
            if not any(chrome_shot(html, png, tmp, (IW, IH)) for _ in range(3)):
                raise SystemExit(f"그리지 못했다: {png}")
            print("rendered", png.relative_to(ROOT))


if __name__ == "__main__":
    for lang in (sys.argv[1:] or list(SHOTS)):
        render(lang)
