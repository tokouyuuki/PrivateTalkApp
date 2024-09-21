//
//  CalendarViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/22.
//

import Foundation

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    
    private struct Constants {
        static let FULL_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
    }
    
    // カレンダーのModel
    @Published var calendarModel: CalendarModel?
    // WorlTimeAPIの世界時刻情報を取得するために使用するService
    private let worldTimeService = WorldTimeService()
    
    /// 年月文字列をセット
    /// - parameter date: セットしたいDate
    func setDisplayDate(date: Date?) {
        Task { [weak self] in
            guard let self = self else {
                return
            }
            self.calendarModel = CalendarModel(date: date)
        }
    }
    
    /// 今日ボタンを押下された際の処理
    func tapTodayButton() {
        Task {
            do {
                // 現在の時刻をUTC文字列で取得
                let datetime = try await self.worldTimeService.fetchWorldTime()
                // UTC文字列をUTCのDateに変換
                let currentUtcDate = DateUtilities.convertStringToUtcDate(dateString: datetime,
                                                                          format: Constants.FULL_DATE_FORMAT)
                // UTCのDateからローカルタイムゾーンの年月文字列をセットする
                self.setDisplayDate(date: currentUtcDate)
            } catch {
                // UTCかつ端末に依存する今日の日付をセットする
                self.setDisplayDate(date: Date())
            }
        }
    }
    
    /// 日付がCalendarModelと一致しているかどうか
    /// - parameter dateToCompare: 比較したいDate
    /// - returns: 一致すればtrue / 一致しなければfalse
    func isMatchedDate(dateToCompare: Date) -> Bool {
        // 比較したいDate
        let timestampToCompare = DateUtilities.convertDateToTimestamp(date: dateToCompare)
        // CalendarModelに保存しているDate
        let displayDateTimestamp = DateUtilities.convertDateToTimestamp(date: self.calendarModel?.displayDate)
        
        return displayDateTimestamp == timestampToCompare
    }
}
