//
//  UIColorExtension.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/25.
//

import Foundation
import UIKit

extension UIColor {
    /// 明るさを調整する（0.0~1.0の割合で増減）
    /// - parameter factor: 明るさの度合い
    func adjustedBrightness(by factor: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 現在の色のRGBA値を取得
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 各色の成分にfactorを掛け、0~1の範囲に制限
        let newRed = min(red * factor, 1.0)
        let newGreen = min(green * factor, 1.0)
        let newBlue = min(blue * factor, 1.0)
        
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
    }
}
