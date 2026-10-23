#!/usr/bin/env python3
"""content.py 의 언어별 예시 기록 → <언어>.json (DEBUG 앱의 -demoSeed 가 읽는다).

타임라인 순서가 화면 목록 순서이고, capture_screenshots.sh 의 -demoTimeline 번호다.
  0 아기의 첫 해   1 한 달 살기   2 여행(스크린샷 01~05)   3 회사 생활   4 '첫순간' 태그 타임라인
여행 타임라인의 사건 번호: 0 봄 꽃길 · 1 모래 언덕 · 2 가을 숲 · 3 아이슬란드 첫날 · 4 절벽 폭포 · 5 마지막 폭포 · 6 다시 집으로
사진 IMG_000N 은 iOS 시뮬레이터에 기본으로 들어 있는 사진이다.
"""
import json, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from content import C

HERE = pathlib.Path(__file__).parent


def ev(date, title, note="", tags=(), style="classic", photo=None):
    e = {"date": date, "title": title, "note": note, "tags": list(tags), "style": style}
    if photo:
        e["photo"] = photo
    return e


def seed(t):
    return {"timelines": [
        {"name": t["baby"], "color": "2E6B5E", "events": [
            ev("2024-03-14", t["birth"], t["birth_n"], [t["t_first"]], "editorial"),
            ev("2024-03-17", t["home"], t["home_n"], [t["t_family"]]),
            ev("2024-03-23", t["bath"], "", [t["t_first"]]),
            ev("2024-04-09", t["smile"], t["smile_n"], [t["t_first"]]),
            ev("2024-09-20", t["solids"], t["solids_n"], [t["t_family"]]),
            ev("2025-03-14", t["bday"], t["bday_n"], [t["t_family"]]),
        ]},
        {"name": t["sea"], "color": "3A5BA0", "events": [
            ev("2024-11-02", t["arrive"], "", [t["t_jeju"]]),
            ev("2024-11-16", t["run"], "", [t["t_jeju"], t["t_run"]]),
            ev("2024-11-30", t["back"], "", [t["t_home"]]),
        ]},
        {"name": t["trip"], "color": "2E6B5E", "events": [
            ev("2023-04-08", t["flowers"], "", [t["t_jeju"], t["t_spring"]], "poster", "IMG_0006.HEIC"),
            ev("2023-04-11", t["dune"], t["dune_n"], [t["t_jeju"]], "classic", "IMG_0001.JPG"),
            ev("2023-10-02", t["forest"], "", [t["t_autumn"]], "film", "IMG_0002.JPG"),
            ev("2025-07-19", t["ice"], "", [t["t_ice"], t["t_summer"]], "poster", "IMG_0005.JPG"),
            ev("2025-07-21", t["coast"], "", [t["t_ice"]], "editorial", "IMG_0003.JPG"),
            ev("2025-07-24", t["last"], t["last_n"], [t["t_ice"]], "classic", "IMG_0004.JPG"),
            ev("2026-05-02", t["back"], "", [t["t_home"]]),
        ]},
        {"name": t["work"], "color": "B3472B", "events": [
            ev("2022-03-02", t["w1"], t["w1_n"], [t["t_work"]]),
            ev("2024-06-03", t["w2"], "", [t["t_work"]]),
            ev("2026-04-15", t["w3"], "", [t["t_work"], t["t_run"]]),
        ]},
        {"name": t["t_first"], "color": "8A5A9E", "tagFilter": t["t_first"]},
    ]}


if __name__ == "__main__":
    for lang, t in C.items():
        (HERE / f"{lang}.json").write_text(json.dumps(seed(t), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(C)} seeds")
