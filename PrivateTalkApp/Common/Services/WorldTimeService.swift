//
//  WorldTimeService.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

struct WorldTimeService {
    
    private struct Constants {
        static let UNNECESSARY_CHARACTER: Character = "."
        static let BEFORE_REPLACEMENT_CHARACTER: String = "T"
        static let AFTER_REPLACEMENT_CHARACTER: String = " "
    }
    
    private let worldTimeRepository = WorldTimeRepository()
    
    /// 世界時刻で現在の時刻を取得
    /// - returns: 現在時刻の文字列（UTC）
    func fetchWorldTime() async throws -> String? {
        let worldTimeResponse = try await worldTimeRepository.fetchCurrentTime()
        // レスポンスのdatetimeを正しい文字列に変換
        return trimDateString(dateString: worldTimeResponse.datetime)
    }
    
    /// 不要な文字列を削除（例: 2024-09-30 15:00:00の形式にする）
    /// - parameter dateString: Dateの文字列
    /// - returns: 不要な文字列が削除されたDateString　or　nil
    private func trimDateString(dateString: String?) -> String? {
        guard let dateString = dateString else {
            return nil
        }
        // "."のindexを取得
        if let dotIndex = dateString.firstIndex(of: Constants.UNNECESSARY_CHARACTER) {
            // "T"を半角スペースに置換
            let replacedDateString = dateString.replacingOccurrences(of: Constants.BEFORE_REPLACEMENT_CHARACTER, 
                                                                     with: Constants.AFTER_REPLACEMENT_CHARACTER)
            
            // "."以降の文字列を削除
            return String(replacedDateString.prefix(upTo: dotIndex))
        }
        
        // 不要なものが含まれていない場合、そのまま返す
        return dateString
    }
}
