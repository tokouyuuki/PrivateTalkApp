//
//  Logger.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/09/21.
//

import Foundation
import os

// MARK: - Logger
struct Logger {
    
    private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? String.empty, category: "default")
    
    /// ログを出力
    /// - parameter message: 出力したいログメッセージ
    /// - parameter level: ログの優先度
    /// 　　　　　　　　　　　　.fault: 重大なエラーメッセージ
    /// 　　　　　　　　　　　　.error: エラーメッセージ
    /// 　　　　　　　　　　　　.notice: 通知メッセージ
    /// 　　　　　　　　　　　　.info: 情報メッセージ
    /// 　　　　　　　　　　　　.debug: デバッグ用の詳細な情報
    func log(_ message: String, level: OSLogType) {
        // "ファイルパス＋該当箇所の行番号＋該当箇所の関数名＋メッセージ"をログメッセージとする
        let logMessage = "[\(#file): \(#line)] \(#function) - \(message)"
        logger.log(level: level, "\(logMessage)")
    }
}
