# 결 (Gyeol) — 타임라인 앱

사건 사이의 거리가 **실제로 흐른 시간**만큼 벌어지는 세로 타임라인 앱.
3일과 5일은 3:5로 벌어지고, 2년은 점선으로 압축되어 "2년 4개월"이라 적힙니다.

SwiftUI + SwiftData. iOS 17+, Xcode 16+ (file-system-synchronized groups 사용).

## 열기
1. `Gyeol.xcodeproj` 더블클릭
2. Signing & Capabilities에서 **본인 Team 선택** (프로젝트에는 작성자 팀이 들어 있습니다)
3. Run

## 구조
- `Models/` — `Timeline`(이름·색, cascade delete) / `TimelineEvent`(날짜·제목·내용·사진, external storage)
- `Views/TimelineListView` — 타임라인 목록, 스와이프 삭제
- `Views/TimelineDetailView` — 세로 타임라인 호스트
- `Views/TimelineTrackView` — 세로 척추선. 노드 사이 거리 = 실제 경과 시간(전체에 하나의 pt/day 배율).
  탭하면 사진·내용이 그 자리에서 펼쳐짐
- `Views/EventEditorView` — `PhotosPicker`, 긴 변 1200px JPEG 압축
- `Views/TimelineEditorView` — 이름·색
- `Support/KeyboardDismiss` — 입력 필드 바깥을 탭하면 키보드 내림

## 타임라인 배율
`TrackScale`이 전체 기간에 하나의 pt/day 배율을 적용하므로 같은 기간은 화면 어디서나 같은 거리로 그려집니다.
너무 짧은 간격은 `minGap`(26pt)으로, 너무 긴 간격은 `maxGap`(560pt)으로 잘리며,
잘린 구간은 점선으로 표시됩니다. 모든 간격에는 "2년 4개월" 같은 실제 기간 라벨이 붙습니다.

## 다음 단계 후보
- iCloud 동기화: `.modelContainer(for:)` → `ModelConfiguration(cloudKitDatabase: .automatic)` + CloudKit capability
- 사건당 사진 여러 장, 날짜 정밀도(연도만/월만)
- 배율 확대/축소(핀치)로 압축된 구간 펴보기
- 이미지·PDF로 내보내기
