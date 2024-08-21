//
//  StringExtension.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/21.
//

import Foundation

// MARK: - Constants
private struct Constants {
    static let EMPTY_STRING = ""
}

// MARK: - extension
extension String {
    
    /// 空文字
    static var empty: String {
        return Constants.EMPTY_STRING
    }
}
