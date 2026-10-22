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
STORE = {"ko": "ko", "en": "en", "en-GB": "en-GB", "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant", "ja": "ja", "ru": "ru", "es": "es", "de": "de", "fr": "fr", "it": "it", "pt-BR": "pt-BR", "th": "th", "vi": "vi", "cs": "cs", "da": "da", "el": "el", "fi": "fi", "id": "id", "nb": "nb", "nl": "nl", "pl": "pl", "sv": "sv", "tr": "tr"}
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
    "zh-Hant": [
        ("01-trip.png", "hero-bleed", "依流逝的時間<br>拉開的時間軸", "三天和五天以 3:5 拉開，長空白摺成虛線"),
        ("02-iceland.png", "left-text", "連同照片<br>留下那一天", "四種卡片樣式任你挑選"),
        ("03-expand.png", "text-bottom", "輕點即可就地展開", "照片和故事一目瞭然"),
        ("04-tag.png", "flat-rotate", "用主題標籤<br>重新串聯", "分散的紀錄變成一條新時間軸"),
        ("05-editor.png", "dark", "卡片樣式<br>每個事件自己選", "日期、內容、標籤都在同一個畫面"),
    ],
    "ja": [
        ("01-trip.png", "hero-bleed", "流れた時間どおりに<br>間隔があくタイムライン", "3日と5日は3:5、長い空白は点線に"),
        ("02-iceland.png", "left-text", "写真と一緒に<br>その日を残す", "カードデザインは4種類から選べます"),
        ("03-expand.png", "text-bottom", "タップすると<br>その場で開きます", "写真とできごとをひと目で"),
        ("04-tag.png", "flat-rotate", "ハッシュタグで<br>もう一度つなぐ", "散らばった記録が新しいタイムラインに"),
        ("05-editor.png", "dark", "カードデザインも<br>イベントごとに選べます", "日付も内容もタグも1画面で"),
    ],
    "ru": [
        ("01-trip.png", "hero-bleed", "Таймлайн, где<br>расстояния равны времени", "Три и пять дней — это 3:5, долгие паузы — пунктир"),
        ("02-iceland.png", "left-text", "Сохраните день<br>вместе с фото", "Четыре оформления карточек на выбор"),
        ("03-expand.png", "text-bottom", "Нажмите — и всё раскроется на месте", "Фото и истории с первого взгляда"),
        ("04-tag.png", "flat-rotate", "Собирайте события<br>по хештегам", "Разрозненные записи становятся новым таймлайном"),
        ("05-editor.png", "dark", "Оформление<br>для каждого события", "Дата, заметка и теги на одном экране"),
    ],
    "es": [
        ("01-trip.png", "hero-bleed", "Una línea de tiempo<br>que se estira con el tiempo", "Tres y cinco días a 3:5; los vacíos largos, en puntos"),
        ("02-iceland.png", "left-text", "Guarda el día<br>con sus fotos", "Cuatro diseños de tarjeta a elegir"),
        ("03-expand.png", "text-bottom", "Toca y se abre<br>en el mismo sitio", "Fotos e historias de un vistazo"),
        ("04-tag.png", "flat-rotate", "Une eventos<br>con hashtags", "Los registros sueltos forman una línea nueva"),
        ("05-editor.png", "dark", "Un diseño de tarjeta<br>para cada evento", "Fecha, notas y etiquetas en una pantalla"),
    ],
    "de": [
        ("01-trip.png", "hero-bleed", "Eine Zeitleiste, die<br>mit der Zeit wächst", "Drei und fünf Tage im Verhältnis 3:5, lange Lücken als Punkte"),
        ("02-iceland.png", "left-text", "Halte den Tag<br>mit Fotos fest", "Vier Kartendesigns zur Auswahl"),
        ("03-expand.png", "text-bottom", "Antippen und es<br>öffnet sich direkt", "Fotos und Geschichten auf einen Blick"),
        ("04-tag.png", "flat-rotate", "Ereignisse per<br>Hashtag verknüpfen", "Verstreute Einträge werden zu einer neuen Zeitleiste"),
        ("05-editor.png", "dark", "Ein Kartendesign<br>für jedes Ereignis", "Datum, Notizen und Hashtags auf einem Bildschirm"),
    ],
    "fr": [
        ("01-trip.png", "hero-bleed", "Une frise qui<br>s’étire avec le temps", "Trois et cinq jours à 3:5, les longs vides en pointillés"),
        ("02-iceland.png", "left-text", "Gardez la journée<br>avec ses photos", "Quatre styles de carte au choix"),
        ("03-expand.png", "text-bottom", "Touchez, et tout<br>s’ouvre sur place", "Photos et histoires d’un coup d’œil"),
        ("04-tag.png", "flat-rotate", "Reliez vos événements<br>avec des hashtags", "Des données éparses forment une nouvelle frise"),
        ("05-editor.png", "dark", "Un style de carte<br>pour chaque événement", "Date, notes et tags sur un seul écran"),
    ],
    "it": [
        ("01-trip.png", "hero-bleed", "Una timeline che si<br>allunga con il tempo", "Tre e cinque giorni a 3:5, i vuoti lunghi a puntini"),
        ("02-iceland.png", "left-text", "Conserva il giorno<br>insieme alle foto", "Quattro stili di scheda tra cui scegliere"),
        ("03-expand.png", "text-bottom", "Tocca e si apre<br>sul posto", "Foto e storie a colpo d’occhio"),
        ("04-tag.png", "flat-rotate", "Collega gli eventi<br>con gli hashtag", "I dati sparsi diventano una nuova timeline"),
        ("05-editor.png", "dark", "Uno stile di scheda<br>per ogni evento", "Data, note e tag in una sola schermata"),
    ],
    "pt-BR": [
        ("01-trip.png", "hero-bleed", "Uma linha do tempo que<br>se estica com o tempo", "Três e cinco dias em 3:5, intervalos longos em pontos"),
        ("02-iceland.png", "left-text", "Guarde o dia<br>junto com as fotos", "Quatro designs de cartão à escolha"),
        ("03-expand.png", "text-bottom", "Toque e abre<br>ali mesmo", "Fotos e histórias num relance"),
        ("04-tag.png", "flat-rotate", "Conecte eventos<br>com hashtags", "Registros soltos viram uma nova linha do tempo"),
        ("05-editor.png", "dark", "Um design de cartão<br>para cada evento", "Data, notas e tags numa só tela"),
    ],
    "th": [
        ("01-trip.png", "hero-bleed", "ไทม์ไลน์ที่ห่าง<br>ตามเวลาจริง", "สามวันกับห้าวันห่างกัน 3:5 ช่วงว่างยาวเป็นเส้นประ"),
        ("02-iceland.png", "left-text", "เก็บวันนั้นไว้<br>พร้อมรูป", "เลือกการ์ดได้สี่ดีไซน์"),
        ("03-expand.png", "text-bottom", "แตะแล้วเปิด<br>ออกตรงนั้นเลย", "รูปและเรื่องราวในที่เดียว"),
        ("04-tag.png", "flat-rotate", "โยงเหตุการณ์<br>ด้วยแฮชแท็ก", "ข้อมูลที่กระจัดกระจายกลายเป็นไทม์ไลน์ใหม่"),
        ("05-editor.png", "dark", "เลือกดีไซน์การ์ด<br>ให้แต่ละเหตุการณ์", "วันที่ เนื้อหา แท็ก ในหน้าจอเดียว"),
    ],
    "vi": [
        ("01-trip.png", "hero-bleed", "Dòng thời gian giãn<br>theo thời gian thực", "Ba và năm ngày cách nhau 3:5, khoảng trống dài thành đường chấm"),
        ("02-iceland.png", "left-text", "Giữ lại ngày hôm đó<br>cùng ảnh", "Chọn một trong bốn kiểu thẻ"),
        ("03-expand.png", "text-bottom", "Chạm là mở<br>ngay tại chỗ", "Ảnh và câu chuyện trong một cái nhìn"),
        ("04-tag.png", "flat-rotate", "Gắn kết sự kiện<br>bằng hashtag", "Dữ liệu rải rác thành dòng thời gian mới"),
        ("05-editor.png", "dark", "Mỗi sự kiện<br>một kiểu thẻ", "Ngày, nội dung và thẻ trên một màn hình"),
    ],
    "cs": [
        ("01-trip.png", "hero-bleed", "Časová osa, která se<br>natahuje podle času", "Tři a pět dní v poměru 3:5, dlouhé mezery jako tečky"),
        ("02-iceland.png", "left-text", "Uchovejte den<br>i s fotkami", "Čtyři vzhledy karet na výběr"),
        ("03-expand.png", "text-bottom", "Klepněte a otevře<br>se to na místě", "Fotky a příběhy na první pohled"),
        ("04-tag.png", "flat-rotate", "Propojujte události<br>hashtagy", "Roztroušené záznamy se stanou novou osou"),
        ("05-editor.png", "dark", "Vzhled karty<br>pro každou událost", "Datum, poznámky a štítky na jedné obrazovce"),
    ],
    "da": [
        ("01-trip.png", "hero-bleed", "En tidslinje, der<br>strækker sig med tiden", "Tre og fem dage 3:5, lange huller som prikker"),
        ("02-iceland.png", "left-text", "Gem dagen<br>sammen med billederne", "Fire kortdesigns at vælge imellem"),
        ("03-expand.png", "text-bottom", "Tryk, så åbner<br>det sig på stedet", "Billeder og historier med det samme"),
        ("04-tag.png", "flat-rotate", "Knyt begivenheder<br>sammen med hashtags", "Spredte data bliver til en ny tidslinje"),
        ("05-editor.png", "dark", "Et kortdesign<br>til hver begivenhed", "Dato, noter og tags på én skærm"),
    ],
    "el": [
        ("01-trip.png", "hero-bleed", "Ένα χρονολόγιο που<br>απλώνεται όσο ο χρόνος", "Τρεις και πέντε μέρες 3:5, τα μεγάλα κενά με τελείες"),
        ("02-iceland.png", "left-text", "Κράτα τη μέρα<br>μαζί με τις φωτογραφίες", "Τέσσερις σχεδιάσεις κάρτας να διαλέξεις"),
        ("03-expand.png", "text-bottom", "Πάτα και ανοίγει<br>επιτόπου", "Φωτογραφίες και ιστορίες με μια ματιά"),
        ("04-tag.png", "flat-rotate", "Συνδέστε τα γεγονότα<br>με hashtag", "Τα διάσπαρτα δεδομένα γίνονται νέο χρονολόγιο"),
        ("05-editor.png", "dark", "Μια σχεδίαση κάρτας<br>για κάθε γεγονός", "Ημερομηνία, σημειώσεις και ετικέτες σε μία οθόνη"),
    ],
    "fi": [
        ("01-trip.png", "hero-bleed", "Aikajana, joka venyy<br>ajan mukana", "Kolme ja viisi päivää 3:5, pitkät tauot pisteinä"),
        ("02-iceland.png", "left-text", "Tallenna päivä<br>kuvineen", "Neljä kortin ulkoasua valittavana"),
        ("03-expand.png", "text-bottom", "Napauta, niin se<br>avautuu paikallaan", "Kuvat ja tarinat yhdellä silmäyksellä"),
        ("04-tag.png", "flat-rotate", "Yhdistä tapahtumat<br>hashtageilla", "Hajallaan olevat tiedot muodostavat uuden aikajanan"),
        ("05-editor.png", "dark", "Kortin ulkoasu<br>jokaiselle tapahtumalle", "Päivä, muistiinpanot ja tunnisteet yhdellä näytöllä"),
    ],
    "id": [
        ("01-trip.png", "hero-bleed", "Linimasa yang merenggang<br>sesuai waktu", "Tiga dan lima hari berjarak 3:5, jeda panjang jadi titik"),
        ("02-iceland.png", "left-text", "Simpan harimu<br>bersama foto", "Empat desain kartu bisa dipilih"),
        ("03-expand.png", "text-bottom", "Ketuk dan langsung<br>terbuka di tempat", "Foto dan cerita sekilas pandang"),
        ("04-tag.png", "flat-rotate", "Kaitkan peristiwa<br>dengan hashtag", "Catatan yang tercecer jadi linimasa baru"),
        ("05-editor.png", "dark", "Satu desain kartu<br>untuk tiap peristiwa", "Tanggal, catatan, dan tag dalam satu layar"),
    ],
    "nb": [
        ("01-trip.png", "hero-bleed", "En tidslinje som<br>strekker seg med tiden", "Tre og fem dager 3:5, lange hull som prikker"),
        ("02-iceland.png", "left-text", "Ta vare på dagen<br>sammen med bildene", "Fire kortdesign å velge mellom"),
        ("03-expand.png", "text-bottom", "Trykk, så åpner<br>det seg på stedet", "Bilder og historier med ett blikk"),
        ("04-tag.png", "flat-rotate", "Knytt hendelser<br>sammen med hashtags", "Spredte data blir til en ny tidslinje"),
        ("05-editor.png", "dark", "Ett kortdesign<br>for hver hendelse", "Dato, notater og merker på én skjerm"),
    ],
    "nl": [
        ("01-trip.png", "hero-bleed", "Een tijdlijn die<br>meerekt met de tijd", "Drie en vijf dagen 3:5, lange gaten als stippen"),
        ("02-iceland.png", "left-text", "Bewaar de dag<br>samen met foto’s", "Vier kaartontwerpen om uit te kiezen"),
        ("03-expand.png", "text-bottom", "Tik en het opent<br>ter plekke", "Foto’s en verhalen in één oogopslag"),
        ("04-tag.png", "flat-rotate", "Verbind gebeurtenissen<br>met hashtags", "Losse gegevens worden een nieuwe tijdlijn"),
        ("05-editor.png", "dark", "Een kaartontwerp<br>per gebeurtenis", "Datum, notities en tags op één scherm"),
    ],
    "pl": [
        ("01-trip.png", "hero-bleed", "Oś czasu rozciągająca<br>się wraz z czasem", "Trzy i pięć dni 3:5, długie przerwy jako kropki"),
        ("02-iceland.png", "left-text", "Zachowaj dzień<br>razem ze zdjęciami", "Cztery wyglądy kart do wyboru"),
        ("03-expand.png", "text-bottom", "Dotknij, a otworzy<br>się w tym samym miejscu", "Zdjęcia i historie na jednym ekranie"),
        ("04-tag.png", "flat-rotate", "Łącz wydarzenia<br>hashtagami", "Rozproszone dane tworzą nową oś czasu"),
        ("05-editor.png", "dark", "Osobny wygląd karty<br>dla każdego wydarzenia", "Data, notatki i tagi na jednym ekranie"),
    ],
    "sv": [
        ("01-trip.png", "hero-bleed", "En tidslinje som<br>sträcker sig med tiden", "Tre och fem dagar 3:5, långa luckor som prickar"),
        ("02-iceland.png", "left-text", "Spara dagen<br>tillsammans med bilderna", "Fyra kortdesigner att välja mellan"),
        ("03-expand.png", "text-bottom", "Tryck så öppnas<br>det på plats", "Bilder och berättelser med ett ögonkast"),
        ("04-tag.png", "flat-rotate", "Knyt ihop händelser<br>med hashtags", "Utspridda data blir en ny tidslinje"),
        ("05-editor.png", "dark", "En kortdesign<br>för varje händelse", "Datum, anteckningar och taggar på en skärm"),
    ],
    "tr": [
        ("01-trip.png", "hero-bleed", "Zamanla birlikte<br>uzayan zaman çizelgesi", "Üç ve beş gün 3:5, uzun boşluklar nokta nokta"),
        ("02-iceland.png", "left-text", "Günü fotoğraflarıyla<br>birlikte sakla", "Seçebileceğin dört kart tasarımı"),
        ("03-expand.png", "text-bottom", "Dokun, olduğu yerde<br>açılsın", "Fotoğraf ve hikâyeler tek bakışta"),
        ("04-tag.png", "flat-rotate", "Olayları hashtag’lerle<br>birbirine bağla", "Dağınık kayıtlar yeni bir zaman çizelgesine dönüşür"),
        ("05-editor.png", "dark", "Her olay için<br>ayrı kart tasarımı", "Tarih, not ve etiketler tek ekranda"),
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
    "zh-Hant": [
        ("ipad-01-trip.png", "依流逝的時間拉開的時間軸", "三天和五天以 3:5 拉開，長空白摺成虛線"),
        ("ipad-02-expand.png", "輕點即可就地展開", "照片和故事一目瞭然"),
        ("ipad-03-tag.png", "用主題標籤重新串聯", "分散的紀錄變成一條新時間軸"),
        ("ipad-04-editor.png", "留下那一天的照片和故事", "日期、內容、標籤、卡片樣式"),
    ],
    "ja": [
        ("ipad-01-trip.png", "流れた時間どおりに間隔があくタイムライン", "3日と5日は3:5、長い空白は点線に"),
        ("ipad-02-expand.png", "タップするとその場で開きます", "写真とできごとをひと目で"),
        ("ipad-03-tag.png", "ハッシュタグでもう一度つなぐ", "散らばった記録が新しいタイムラインに"),
        ("ipad-04-editor.png", "その日の写真とできごとを残す", "日付、内容、タグ、カードデザインまで"),
    ],
    "ru": [
        ("ipad-01-trip.png", "Таймлайн, где расстояния равны времени", "Три и пять дней — это 3:5, долгие паузы — пунктир"),
        ("ipad-02-expand.png", "Нажмите — и всё раскроется на месте", "Фото и истории с первого взгляда"),
        ("ipad-03-tag.png", "Собирайте события по хештегам", "Разрозненные записи становятся новым таймлайном"),
        ("ipad-04-editor.png", "Фото и история того дня", "Дата, заметка, теги и оформление карточки"),
    ],
    "es": [
        ("ipad-01-trip.png", "Una línea de tiempo que se estira con el tiempo", "Tres y cinco días a 3:5; los vacíos largos, en puntos"),
        ("ipad-02-expand.png", "Toca y se abre en el mismo sitio", "Fotos e historias de un vistazo"),
        ("ipad-03-tag.png", "Une eventos con hashtags", "Los registros sueltos forman una línea nueva"),
        ("ipad-04-editor.png", "Guarda las fotos y la historia del día", "Fecha, notas, etiquetas y diseño de tarjeta"),
    ],
    "de": [
        ("ipad-01-trip.png", "Eine Zeitleiste, die mit der Zeit wächst", "Drei und fünf Tage im Verhältnis 3:5, lange Lücken als Punkte"),
        ("ipad-02-expand.png", "Antippen und es öffnet sich direkt", "Fotos und Geschichten auf einen Blick"),
        ("ipad-03-tag.png", "Ereignisse per Hashtag verknüpfen", "Verstreute Einträge werden zu einer neuen Zeitleiste"),
        ("ipad-04-editor.png", "Fotos und Geschichte des Tages festhalten", "Datum, Notizen, Hashtags und Kartendesign"),
    ],
    "fr": [
        ("ipad-01-trip.png", "Une frise qui s’étire avec le temps", "Trois et cinq jours à 3:5, les longs vides en pointillés"),
        ("ipad-02-expand.png", "Touchez, et tout s’ouvre sur place", "Photos et histoires d’un coup d’œil"),
        ("ipad-03-tag.png", "Reliez vos événements avec des hashtags", "Des données éparses forment une nouvelle frise"),
        ("ipad-04-editor.png", "Gardez les photos et l’histoire du jour", "Date, notes, tags et style de carte"),
    ],
    "it": [
        ("ipad-01-trip.png", "Una timeline che si allunga con il tempo", "Tre e cinque giorni a 3:5, i vuoti lunghi a puntini"),
        ("ipad-02-expand.png", "Tocca e si apre sul posto", "Foto e storie a colpo d’occhio"),
        ("ipad-03-tag.png", "Collega gli eventi con gli hashtag", "I dati sparsi diventano una nuova timeline"),
        ("ipad-04-editor.png", "Conserva foto e storia del giorno", "Data, note, tag e stile di scheda"),
    ],
    "pt-BR": [
        ("ipad-01-trip.png", "Uma linha do tempo que se estica com o tempo", "Três e cinco dias em 3:5, intervalos longos em pontos"),
        ("ipad-02-expand.png", "Toque e abre ali mesmo", "Fotos e histórias num relance"),
        ("ipad-03-tag.png", "Conecte eventos com hashtags", "Registros soltos viram uma nova linha do tempo"),
        ("ipad-04-editor.png", "Guarde as fotos e a história do dia", "Data, notas, tags e design do cartão"),
    ],
    "th": [
        ("ipad-01-trip.png", "ไทม์ไลน์ที่ห่างตามเวลาจริง", "สามวันกับห้าวันห่างกัน 3:5 ช่วงว่างยาวเป็นเส้นประ"),
        ("ipad-02-expand.png", "แตะแล้วเปิดออกตรงนั้นเลย", "รูปและเรื่องราวในที่เดียว"),
        ("ipad-03-tag.png", "โยงเหตุการณ์ด้วยแฮชแท็ก", "ข้อมูลที่กระจัดกระจายกลายเป็นไทม์ไลน์ใหม่"),
        ("ipad-04-editor.png", "เก็บรูปและเรื่องราวของวันนั้น", "วันที่ เนื้อหา แท็ก และดีไซน์การ์ด"),
    ],
    "vi": [
        ("ipad-01-trip.png", "Dòng thời gian giãn theo thời gian thực", "Ba và năm ngày cách nhau 3:5, khoảng trống dài thành đường chấm"),
        ("ipad-02-expand.png", "Chạm là mở ngay tại chỗ", "Ảnh và câu chuyện trong một cái nhìn"),
        ("ipad-03-tag.png", "Gắn kết sự kiện bằng hashtag", "Dữ liệu rải rác thành dòng thời gian mới"),
        ("ipad-04-editor.png", "Giữ lại ảnh và câu chuyện của ngày", "Ngày, nội dung, thẻ và kiểu thẻ"),
    ],
    "cs": [
        ("ipad-01-trip.png", "Časová osa, která se natahuje podle času", "Tři a pět dní v poměru 3:5, dlouhé mezery jako tečky"),
        ("ipad-02-expand.png", "Klepněte a otevře se to na místě", "Fotky a příběhy na první pohled"),
        ("ipad-03-tag.png", "Propojujte události hashtagy", "Roztroušené záznamy se stanou novou osou"),
        ("ipad-04-editor.png", "Uchovejte fotky a příběh dne", "Datum, poznámky, štítky a vzhled karty"),
    ],
    "da": [
        ("ipad-01-trip.png", "En tidslinje, der strækker sig med tiden", "Tre og fem dage 3:5, lange huller som prikker"),
        ("ipad-02-expand.png", "Tryk, så åbner det sig på stedet", "Billeder og historier med det samme"),
        ("ipad-03-tag.png", "Knyt begivenheder sammen med hashtags", "Spredte data bliver til en ny tidslinje"),
        ("ipad-04-editor.png", "Gem dagens billeder og historie", "Dato, noter, tags og kortdesign"),
    ],
    "el": [
        ("ipad-01-trip.png", "Ένα χρονολόγιο που απλώνεται όσο ο χρόνος", "Τρεις και πέντε μέρες 3:5, τα μεγάλα κενά με τελείες"),
        ("ipad-02-expand.png", "Πάτα και ανοίγει επιτόπου", "Φωτογραφίες και ιστορίες με μια ματιά"),
        ("ipad-03-tag.png", "Συνδέστε τα γεγονότα με hashtag", "Τα διάσπαρτα δεδομένα γίνονται νέο χρονολόγιο"),
        ("ipad-04-editor.png", "Κράτα τις φωτογραφίες και την ιστορία της μέρας", "Ημερομηνία, σημειώσεις, ετικέτες και σχεδίαση κάρτας"),
    ],
    "fi": [
        ("ipad-01-trip.png", "Aikajana, joka venyy ajan mukana", "Kolme ja viisi päivää 3:5, pitkät tauot pisteinä"),
        ("ipad-02-expand.png", "Napauta, niin se avautuu paikallaan", "Kuvat ja tarinat yhdellä silmäyksellä"),
        ("ipad-03-tag.png", "Yhdistä tapahtumat hashtageilla", "Hajallaan olevat tiedot muodostavat uuden aikajanan"),
        ("ipad-04-editor.png", "Tallenna päivän kuvat ja tarina", "Päivä, muistiinpanot, tunnisteet ja kortin ulkoasu"),
    ],
    "id": [
        ("ipad-01-trip.png", "Linimasa yang merenggang sesuai waktu", "Tiga dan lima hari berjarak 3:5, jeda panjang jadi titik"),
        ("ipad-02-expand.png", "Ketuk dan langsung terbuka di tempat", "Foto dan cerita sekilas pandang"),
        ("ipad-03-tag.png", "Kaitkan peristiwa dengan hashtag", "Catatan yang tercecer jadi linimasa baru"),
        ("ipad-04-editor.png", "Simpan foto dan cerita hari itu", "Tanggal, catatan, tag, dan desain kartu"),
    ],
    "nb": [
        ("ipad-01-trip.png", "En tidslinje som strekker seg med tiden", "Tre og fem dager 3:5, lange hull som prikker"),
        ("ipad-02-expand.png", "Trykk, så åpner det seg på stedet", "Bilder og historier med ett blikk"),
        ("ipad-03-tag.png", "Knytt hendelser sammen med hashtags", "Spredte data blir til en ny tidslinje"),
        ("ipad-04-editor.png", "Ta vare på dagens bilder og historie", "Dato, notater, merker og kortdesign"),
    ],
    "nl": [
        ("ipad-01-trip.png", "Een tijdlijn die meerekt met de tijd", "Drie en vijf dagen 3:5, lange gaten als stippen"),
        ("ipad-02-expand.png", "Tik en het opent ter plekke", "Foto’s en verhalen in één oogopslag"),
        ("ipad-03-tag.png", "Verbind gebeurtenissen met hashtags", "Losse gegevens worden een nieuwe tijdlijn"),
        ("ipad-04-editor.png", "Bewaar de foto’s en het verhaal van de dag", "Datum, notities, tags en kaartontwerp"),
    ],
    "pl": [
        ("ipad-01-trip.png", "Oś czasu rozciągająca się wraz z czasem", "Trzy i pięć dni 3:5, długie przerwy jako kropki"),
        ("ipad-02-expand.png", "Dotknij, a otworzy się w tym samym miejscu", "Zdjęcia i historie na jednym ekranie"),
        ("ipad-03-tag.png", "Łącz wydarzenia hashtagami", "Rozproszone dane tworzą nową oś czasu"),
        ("ipad-04-editor.png", "Zachowaj zdjęcia i historię dnia", "Data, notatki, tagi i wygląd karty"),
    ],
    "sv": [
        ("ipad-01-trip.png", "En tidslinje som sträcker sig med tiden", "Tre och fem dagar 3:5, långa luckor som prickar"),
        ("ipad-02-expand.png", "Tryck så öppnas det på plats", "Bilder och berättelser med ett ögonkast"),
        ("ipad-03-tag.png", "Knyt ihop händelser med hashtags", "Utspridda data blir en ny tidslinje"),
        ("ipad-04-editor.png", "Spara dagens bilder och berättelse", "Datum, anteckningar, taggar och kortdesign"),
    ],
    "tr": [
        ("ipad-01-trip.png", "Zamanla birlikte uzayan zaman çizelgesi", "Üç ve beş gün 3:5, uzun boşluklar nokta nokta"),
        ("ipad-02-expand.png", "Dokun, olduğu yerde açılsın", "Fotoğraf ve hikâyeler tek bakışta"),
        ("ipad-03-tag.png", "Olayları hashtag’lerle birbirine bağla", "Dağınık kayıtlar yeni bir zaman çizelgesine dönüşür"),
        ("ipad-04-editor.png", "O günün fotoğraflarını ve hikâyesini sakla", "Tarih, not, etiket ve kart tasarımı"),
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
