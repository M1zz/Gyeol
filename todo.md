# 여울 — 작업 목록

## 완료
- [x] 빌드 에러 해결 — `DEVELOPMENT_TEAM = QGAQ3AY3R3`을 Debug/Release 타겟에 추가
      (원인: 팀 미설정 → 실기기 빌드 시 "Signing for 'Gyeol' requires a development team")
- [x] 키보드가 안 내려가는 문제 — `@FocusState` + 키보드 툴바 "완료" +
      드래그로 내리기(`scrollDismissesKeyboard`) + 입력 필드 바깥 탭 시 내림(`Support/KeyboardDismiss`)
- [x] 타임라인을 세로로 전환 (`TimelineTrackView`) — 아이폰 세로 비율에 맞춤
- [x] 시간 간격을 절대적으로 표현 — 전체에 하나의 pt/day 배율. 시뮬레이터에서 3일:5일 = 285px:475px로 검증
- [x] 노드 탭 → 사진·내용이 그 자리에서 펼쳐짐 (`.snappy` 0.32s)
- [x] 사진이 카드 폭을 밀어내던 레이아웃 버그 수정 (`scaledToFill` → 레이아웃에 관여 않는 오버레이)
- [x] 빌드 검증 — Debug/Release × 시뮬레이터/실기기 4개 구성 에러·경고 0

- [x] 마일스톤 카드 날짜로 그 날 찍은 사진 찾기 (`Support/DayPhotoFinder`) → 직접 찾기로 이어짐
      시뮬레이터 검증: 예측자 matched=3, 썸네일 3장, 원본 551x1200 / 47KB 압축까지 확인
- [x] 썸네일이 항상 nil이던 버그 수정 — `.fastFormat`은 캐시 없는 사진에 nil을 반환

- [x] 사건에 해시태그 달기 — 칩 표시, 기존 태그 자동 추천
- [x] 태그를 누르면 그 태그의 모든 사건으로 타임라인 재구성 (`TagTimelineView`)
- [x] 재구성한 타임라인 저장 — `Timeline.tagFilter`를 쓰는 '저장된 뷰' 방식
      시뮬레이터 검증: 두 타임라인에 걸친 #처음 4개 수집, 목록에 태그 타임라인 표시,
      삭제해도 사건 5개 그대로(before=5 after=5), 구 스키마 데이터 마이그레이션 성공
- [x] 태그 색이 실행마다 바뀌던 버그 수정 — `hashValue`는 프로세스마다 시드가 다름

- [x] 카드 디자인 4종(기본·포스터·필름·여백) — 사진과 타이포를 살린 레이아웃
- [x] 카드마다 디자인 선택 + 도식 스와치 + 실시간 미리보기
      시뮬레이터 검증: 4종 렌더, Form 안 미리보기 레이아웃, styleID 마이그레이션 성공

- [x] 앱 아이콘 — 명조 '결' + 옅은 결무늬 바탕, 라이트/다크/틴트 3종
      (`Tools/MakeAppIcon.swift`로 재생성 가능). 이전에 비어 있어 제출 검증에 걸리던 항목

- [x] 앱 이름 '결' → '여울' (App Store 이름은 2글자 이상이어야 함)
      표시 이름·앱 내 제목·아이콘 교체. 프로젝트/번들 ID는 Gyeol 그대로

## 다음 단계 후보
- [ ] 압축된 구간(점선)을 핀치로 펴보기
- [ ] iCloud 동기화: `ModelConfiguration(cloudKitDatabase: .automatic)` + CloudKit capability
- [ ] 사건당 사진 여러 장, 날짜 정밀도(연도만/월만)
- [ ] 이미지·PDF로 내보내기
- [ ] 제한 접근(limited) 시 `presentLimitedLibraryPicker`로 사진 더 고르기
- [ ] 날짜로 찾기를 사진 외 다른 기록(메모 등)으로 확장
- [ ] 태그 여러 개를 AND/OR로 묶어 재구성하기
- [ ] 태그 이름 바꾸기·병합
- [ ] 타임라인 단위로 카드 디자인 일괄 변경
- [ ] 카드 이미지로 내보내 공유하기
- [ ] 원하면 프로젝트·타깃·번들 ID까지 Yeoul로 개명 (번들 ID 변경은 스토어 레코드에 영향)
