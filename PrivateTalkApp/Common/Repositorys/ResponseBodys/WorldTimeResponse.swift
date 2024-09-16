//
//  WorldTimeResponse.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

struct WorldTimeResponse: Decodable {
    
    // 現在の時刻（UTC）
    let datetime: String?
    
    /// アプリ内で使える形式に直すために新しくインスタンス化する
    func updatedDatetimeProperty(newDatetime: String?) -> WorldTimeResponse {
        return WorldTimeResponse(datetime: newDatetime)
    }
}
