#!/usr/bin/env python3
"""App Store 크리에이티브 자산(제품 페이지 헤더 · 검색 결과) 생성: HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_creative_assets.py [언어 ...]     (없으면 전부)

자리
  docs/screenshots/creative/<스토어 로케일>/header.png   3840x1646  제품 페이지 맨 위
  docs/screenshots/creative/<스토어 로케일>/search.png   3840x2560  검색 결과 (없으면 스크린샷이 대신 보인다)

기기 화면 재료: docs/screenshots/raw/creative/<언어>/
  01-timeline.png  타임라인 상세 (사건 사이가 실제 흐른 시간만큼 벌어진 화면)
  02-list.png      타임라인 목록
  시뮬레이터(iPhone 17 Pro Max)에서 -localOnly 로 띄워 예시 기록을 넣고 찍은 것이다.

⚠️ 안전 영역 밖은 기기에 따라 잘린다. 글은 **반드시** 안전 영역 안에 둔다(배경 · 기기 그림은 넘쳐도 된다).
   수치는 Apple 공식 PSD 템플릿에서 잰 값이다(https://developer.apple.com/app-store/asset-best-practices/).
   아이폰에서 헤더는 가운데만 남고, 검색 결과는 약 385pt 폭으로 줄어 보인다. 그래서 글이 크다.

⚠️ 가격 · 할인 · 주소(URL) · 수상 · 다른 플랫폼 이름은 넣지 않는다(Apple 가이드).
"""
import subprocess, sys, pathlib, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw" / "creative"
OUT = ROOT / "docs" / "screenshots" / "creative"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 앱 언어 코드 → App Store Connect 로케일. 스토어에는 한국어만 있다.
STORE = {}

# (가로, 세로, 안전 영역 left, top, right, bottom)
SPEC = {
    "header": (3840, 1646, (1097, 493, 2743, 1154)),
    "search": (3840, 2560, (836, 765, 3004, 1795)),
}

# 검색 결과 글 칸을 넓게 쓰는 언어 (헤드라인이 두 줄에 안 들어간다)
WIDE_SEARCH = {"de", "fr", "it", "vi", "cs", "da", "el", "fi", "id", "nb", "nl", "sv"}

# 검색 결과: 눈썹글(그 나라 검색어) · 헤드라인 · 보조 한 줄. 기기 화면(타임라인)과 같은 이야기다.
SEARCH = {
    "ko": ("타임라인 기록", "3일은 3일만큼,<br>2년은 2년만큼", "사건 사이가 실제로 흐른 시간만큼 벌어져요"),
    "en": ("timeline journal", "3 days stay 3 days,<br>2 years stay 2 years", "Gaps between events match the time that really passed"),
    "en-GB": ("timeline diary", "3 days stay 3 days,<br>2 years stay 2 years", "Gaps between events match the time that really passed"),
    "zh-Hans": ("时间线日记", "3 天就是 3 天，<br>2 年就是 2 年", "事件之间的间隔与实际流逝的时间一致"),
    "zh-Hant": ("時間軸日記", "3 天就是 3 天，<br>2 年就是 2 年", "事件之間的間隔與實際流逝的時間一致"),
    "ja": ("タイムライン 記録", "3日は3日分、<br>2年は2年分", "イベントの間隔が実際に流れた時間どおりにあきます"),
    "ru": ("таймлайн дневник", "3 дня — это 3 дня,<br>2 года — это 2 года", "Расстояния между событиями равны реально прошедшему времени"),
    "es": ("diario línea de tiempo", "3 días son 3 días,<br>2 años son 2 años", "La distancia entre eventos es el tiempo que pasó de verdad"),
    "de": ("Zeitleiste Tagebuch", "3 Tage sind 3 Tage,<br>2 Jahre sind 2 Jahre", "Die Abstände zeigen die wirklich vergangene Zeit"),
    "fr": ("frise journal", "3 jours restent 3 jours,<br>2 ans restent 2 ans", "L’écart entre les événements suit le temps réellement écoulé"),
    "it": ("timeline diario", "3 giorni sono 3 giorni,<br>2 anni sono 2 anni", "Le distanze seguono il tempo trascorso davvero"),
    "pt-BR": ("linha do tempo diário", "3 dias são 3 dias,<br>2 anos são 2 anos", "A distância entre eventos é o tempo que realmente passou"),
    "th": ("ไทม์ไลน์ ไดอารี่", "3 วันก็คือ 3 วัน<br>2 ปีก็คือ 2 ปี", "ระยะห่างระหว่างเหตุการณ์ตรงกับเวลาที่ผ่านไปจริง"),
    "vi": ("dòng thời gian nhật ký", "3 ngày vẫn là 3 ngày,<br>2 năm vẫn là 2 năm", "Khoảng cách giữa các sự kiện bằng thời gian thực đã trôi qua"),
    "cs": ("časová osa deník", "3 dny zůstanou 3 dny,<br>2 roky zůstanou 2 roky", "Mezery mezi událostmi odpovídají skutečně uplynulému času"),
    "da": ("tidslinje dagbog", "3 dage forbliver 3 dage,<br>2 år forbliver 2 år", "Afstanden mellem begivenheder svarer til den tid, der faktisk er gået"),
    "el": ("χρονολόγιο ημερολόγιο", "Ο χρόνος<br>όπως πέρασε", "3 μέρες ή 2 χρόνια, στη σωστή απόσταση"),
    "fi": ("aikajana päiväkirja", "3 päivää on 3 päivää,<br>2 vuotta on 2 vuotta", "Välit vastaavat todella kulunutta aikaa"),
    "id": ("linimasa jurnal", "3 hari tetap 3 hari,<br>2 tahun tetap 2 tahun", "Jarak antarperistiwa sebesar waktu yang benar-benar berlalu"),
    "nb": ("tidslinje dagbok", "3 dager forblir 3 dager,<br>2 år forblir 2 år", "Avstanden mellom hendelsene tilsvarer tiden som faktisk har gått"),
    "nl": ("tijdlijn dagboek", "3 dagen zijn 3 dagen,<br>2 jaar is 2 jaar", "De afstand is de tijd die echt verstreek"),
    "pl": ("oś czasu dziennik", "3 dni to 3 dni,<br>2 lata to 2 lata", "Odstępy między wydarzeniami odpowiadają czasowi, który naprawdę minął"),
    "sv": ("tidslinje dagbok", "3 dagar förblir 3 dagar,<br>2 år förblir 2 år", "Avståndet mellan händelser är tiden som faktiskt har gått"),
    "tr": ("zaman çizelgesi günlük", "3 gün 3 gün kalır,<br>2 yıl 2 yıl kalır", "Olaylar arasındaki mesafe gerçekten geçen süre kadardır"),
}

# 헤더는 처음 온 사람에게 한 가지 약속만 한다: 흐른 시간이 그대로 보이는 타임라인.
HEADER = {
    "ko": ("나만의 타임라인", "흐른 시간만큼<br>벌어지는 타임라인"),
    "en": ("Your own timeline", "A timeline that stretches<br>with the time that passed"),
    "en-GB": ("Your own timeline", "A timeline that stretches<br>with the time that passed"),
    "zh-Hans": ("属于你的时间线", "按流逝的时间<br>拉开的时间线"),
    "zh-Hant": ("屬於你的時間軸", "依流逝的時間<br>拉開的時間軸"),
    "ja": ("わたしのタイムライン", "流れた時間どおりに<br>間隔があくタイムライン"),
    "ru": ("Ваш таймлайн", "Таймлайн, где расстояния<br>равны времени"),
    "es": ("Tu propia línea de tiempo", "Una línea de tiempo que<br>se estira con el tiempo"),
    "de": ("Deine eigene Zeitleiste", "Eine Zeitleiste, die<br>mit der Zeit wächst"),
    "fr": ("Votre propre frise", "Une frise qui s’étire<br>avec le temps"),
    "it": ("La tua timeline", "Una timeline che si allunga<br>con il tempo"),
    "pt-BR": ("Sua própria linha do tempo", "Uma linha do tempo que<br>se estica com o tempo"),
    "th": ("ไทม์ไลน์ของคุณเอง", "ไทม์ไลน์ที่ห่าง<br>ตามเวลาจริง"),
    "vi": ("Dòng thời gian của riêng bạn", "Dòng thời gian giãn<br>theo thời gian thực"),
    "cs": ("Vaše vlastní časová osa", "Časová osa, která se<br>natahuje podle času"),
    "da": ("Din egen tidslinje", "En tidslinje, der<br>strækker sig med tiden"),
    "el": ("Το δικό σου χρονολόγιο", "Ένα χρονολόγιο που<br>απλώνεται όσο ο χρόνος"),
    "fi": ("Oma aikajanasi", "Aikajana, joka venyy<br>ajan mukana"),
    "id": ("Linimasamu sendiri", "Linimasa yang merenggang<br>sesuai waktu"),
    "nb": ("Din egen tidslinje", "En tidslinje som<br>strekker seg med tiden"),
    "nl": ("Je eigen tijdlijn", "Een tijdlijn die<br>meerekt met de tijd"),
    "pl": ("Twoja własna oś czasu", "Oś czasu rozciągająca<br>się wraz z czasem"),
    "sv": ("Din egen tidslinje", "En tidslinje som<br>sträcker sig med tiden"),
    "tr": ("Kendi zaman çizelgen", "Zamanla birlikte<br>uzayan zaman çizelgesi"),
}

# 바탕은 앱 아이콘의 초록(#347669 → #235146)과 크림색 글씨를 따른다. 아이콘의 가로 괘선도 옅게 깐다.
BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:linear-gradient(160deg, #347669 0%%, #2a6255 45%%, #1f4a40 100%%); position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", sans-serif; }
.rules { position:absolute; inset:0;
  background:repeating-linear-gradient(180deg, rgba(255,255,255,0) 0 46px, rgba(255,255,255,.035) 46px 48px); }
.glow { position:absolute; border-radius:50%%; filter:blur(160px); pointer-events:none; }
.text { position:absolute; display:flex; flex-direction:column; justify-content:center; }
.eyebrow { font-weight:700; color:#bfe3d5; letter-spacing:-0.01em; line-height:1.15; }
.headline { font-weight:800; color:#f6f0e3; letter-spacing:-0.03em; line-height:1.14; text-wrap:balance; }
.sub { font-weight:500; color:rgba(246,240,227,.72); letter-spacing:-0.01em; line-height:1.35; text-wrap:balance; }
:lang(ko) .headline, :lang(ko) .sub, :lang(ko) .eyebrow { word-break:keep-all; }
.phone { position:absolute; background:#101614; border:6px solid #3d4a46; padding:40px; border-radius:190px;
  box-shadow: 0 60px 160px rgba(0,0,0,.45), 0 0 0 2px #1d2624 inset; }
.phone img { width:100%%; display:block; border-radius:152px; }
.spine { position:absolute; width:8px; background:rgba(246,240,227,.22); border-radius:4px; }
.node { position:absolute; width:44px; height:44px; border-radius:50%%; border:8px solid rgba(246,240,227,.45); }
"""

# 글이 상자를 넘지 않을 때까지 줄인다. 잘리는 글은 없다 - 끝까지 안 맞으면 표시하고 멈춘다.
FIT_JS = """
<script>
// 문구에 적은 줄(<br>)보다 더 쪼개지면 "Rispondi / con un / tocco" 처럼 읽기가 끊긴다.
// 적은 줄 수를 지킬 때까지 줄인다.
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(box, el, max, min) {
  const want = el.querySelectorAll('br').length + 1;
  let size = max;
  el.style.fontSize = size + 'px';
  while (size > min && (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 ||
         lines(el) > want)) {
    size -= 4; el.style.fontSize = size + 'px';
  }
  if (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 || lines(el) > want)
    document.body.dataset.overflow = '1';
}
document.fonts.ready.then(() => {
  const box = document.querySelector('.text');
  const h = document.querySelector('.headline');
  fit(box, h, +h.dataset.max, +h.dataset.min);
  document.body.dataset.done = '1';
});
</script>
"""


def phone(img, left, top, width, rotate=0):
    return (f'<div class="phone" style="left:{left}px;top:{top}px;width:{width}px;'
            f'transform:rotate({rotate}deg)"><img src="{img}"></div>')


def spine(x, top, nodes):
    """앱의 세로 척추선 모양. 마디 사이가 고르지 않은 것이 이 앱의 요점이다. 장식이라 잘려도 된다."""
    h = max(nodes) + 120
    html = f'<div class="spine" style="left:{x}px;top:{top}px;height:{h}px"></div>'
    for y in nodes:
        html += f'<div class="node" style="left:{x - 18}px;top:{top + y}px"></div>'
    return html


def search_html(lang):
    W, H, (l, t, r, b) = SPEC["search"]
    eyebrow, headline, sub = SEARCH[lang]
    sw, sh = r - l, b - t
    # 낱말이 긴 언어는 글 칸을 넓힌다(기기 그림이 오른쪽으로 더 넘친다 — 그림은 잘려도 된다).
    col = int(sw * (0.66 if lang in WIDE_SEARCH else 0.56))
    # 기기는 안전 영역 오른쪽 몫에 서서, 위아래로 넘쳐 화면 밖까지 이어진다(기기 그림은 잘려도 된다).
    ph_w = 1040
    ph_left = l + col + int(sw * 0.04)
    img = (RAW / lang / "01-timeline.png").as_uri()
    return f"""
<div class="rules"></div>
<div class="glow" style="left:{ph_left - 300}px;top:500px;width:1700px;height:1700px;background:rgba(191,227,213,.16)"></div>
{spine(380, -60, [180, 260, 420, 980, 2120])}
{phone(img, ph_left, t - 360, ph_w, 0)}
<div class="text" style="left:{l}px;top:{t}px;width:{col}px;height:{sh}px">
  <div class="eyebrow" style="font-size:96px">{eyebrow}</div>
  <div class="headline" data-max="250" data-min="140" style="margin-top:36px">{headline}</div>
  <div class="sub" style="font-size:84px;margin-top:52px">{sub}</div>
</div>"""


def header_html(lang):
    W, H, (l, t, r, b) = SPEC["header"]
    eyebrow, headline = HEADER[lang]
    sw, sh = r - l, b - t
    left_img = (RAW / lang / "02-list.png").as_uri()
    right_img = (RAW / lang / "01-timeline.png").as_uri()
    return f"""
<div class="rules"></div>
<div class="glow" style="left:{l - 200}px;top:{t - 400}px;width:{sw + 400}px;height:{sh + 800}px;background:rgba(191,227,213,.12)"></div>
{spine(110, -40, [120, 190, 520, 1400])}
{spine(3730, -40, [300, 360, 470, 1160])}
{phone(left_img, 300, 360, 640, -9)}
{phone(right_img, 2900, 360, 640, 9)}
<div class="text" style="left:{l}px;top:{t}px;width:{sw}px;height:{sh}px;align-items:center;text-align:center">
  <div class="eyebrow" style="font-size:76px">{eyebrow}</div>
  <div class="headline" data-max="210" data-min="110" style="margin-top:22px">{headline}</div>
</div>"""


def render(lang, kind):
    W, H, _ = SPEC[kind]
    body = search_html(lang) if kind == "search" else header_html(lang)
    page = (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>'
            f'{BASE_CSS % {"W": W, "H": H}}</style></head><body>{body}{FIT_JS}</body></html>')
    html_path = pathlib.Path(tempfile.gettempdir()) / f"yeoul-creative-{lang}-{kind}.html"
    html_path.write_text(page, encoding="utf-8")
    # 글이 끝까지 안 맞으면 그림을 만들지 않는다(잘린 글이 스토어에 올라가는 것보다 낫다).
    dom = subprocess.run([CHROME, "--headless=new", "--dump-dom", f"--window-size={W},{H}",
                          "--force-device-scale-factor=1", "--disable-gpu", "--virtual-time-budget=3000",
                          html_path.as_uri()], capture_output=True, text=True, timeout=90).stdout
    if 'data-done="1"' not in dom:
        raise SystemExit(f"글 맞추기가 끝나지 않았다: {lang} {kind}")
    if 'data-overflow="1"' in dom:
        raise SystemExit(f"글이 안전 영역을 넘는다: {lang} {kind} - 문구를 줄일 것")
    out_dir = OUT / STORE.get(lang, lang)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{kind}.png"
    # ⚠️ Chrome 은 가끔 아무것도 안 그리고 끝나거나 멈춘다. 세 번까지 한다.
    for _ in range(3):
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=3000",
                                "--allow-file-access-from-files", html_path.as_uri()],
                               capture_output=True, timeout=90)
        except subprocess.TimeoutExpired:
            continue
        if r.returncode == 0:
            break
    else:
        raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
    print(f"rendered {out_png}")


if __name__ == "__main__":
    langs = sys.argv[1:] or list(SEARCH)
    for lang in langs:
        if lang not in SEARCH:
            raise SystemExit(f"모르는 언어: {lang} (아는 것: {', '.join(SEARCH)})")
        for kind in ("header", "search"):
            render(lang, kind)
