//
//  WorldTimeService.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

final class WorldTimeService {
    
    private let worldTimeRepository = WorldTimeRepository()
    
    func fetchWorldTimeApi() async throws -> WorldTimeResponse {
        let worldTimeResponse = try await worldTimeRepository.fetchCurrentTime()
        // レスポンスのdatetimeを正しい文字列に変換
        let correctDateString = trimDateString(dateString: worldTimeResponse.datetime)
        // 正しい文字列でレスポンスを再生成
        let newWorldTimeResponse = worldTimeResponse.updatedDatetimeProperty(newDatetime: correctDateString)
        
        return newWorldTimeResponse
    }
    
    /// 不要な文字列を削除（例: 2024-09-30 15:00:00の形式にする）
    /// - parameter dateString: Dateの文字列
    /// - returns: 不要な文字列が削除されたDateString　or　nil
    private func trimDateString(dateString: String?) -> String? {
        guard let dateString = dateString else {
            return nil
        }
        // "."以降の文字列を削除
        if let dotIndex = dateString.firstIndex(of: ".") {
            // "T"を半角スペースに置換
            let replacedDateString = dateString.replacingOccurrences(of: "T", with: " ")
            
            return String(replacedDateString.prefix(upTo: dotIndex))
        }
        
        // 不要なものが含まれていない場合、そのまま返す
        return dateString
    }
}
