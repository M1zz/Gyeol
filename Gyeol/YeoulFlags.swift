//
//  YeoulFlags.swift
//  Gyeol
//
//  원격 킬스위치 — LeeoKit(LeeoRemoteFlags)이 FeedbackHub 의 RemoteFlags 레코드에서 읽는다.
//
//  ⚠️ rawValue = CloudKit 필드명 계약이다. 바꾸면 아무리 꺼도 켜진 채로 돈다. 변경 금지.
//  ⚠️ 조회 실패 = 켬(가용성 우선). 갱신은 6시간 쓰로틀이고, 값은 **다음 실행부터** 반영된다.
//
//  CloudKit Dashboard (iCloud.com.Ysoup.FeedbackHub, 1회): 레코드 타입 RemoteFlags,
//  recordName "flags_com.leeo.yeoul", 각 플래그를 Int64(1=켬/0=끔) 필드로 만들고 Production 배포.
//  필드가 없으면 켬으로 동작한다.
//

import Foundation
import LeeoKit

enum YeoulFlag: String, LeeoRemoteFlag, CaseIterable {
    /// iCloud(CloudKit) 기록 동기화. 끄면 다음 실행부터 같은 기기 저장소를 iCloud 미러링 없이 연다 —
    /// 기기의 기록은 그대로 남고 동기화만 멈춘다. 동기화가 기록을 망가뜨리는 사고가 나면 심사 없이 끈다.
    case cloudSyncEnabled
}
