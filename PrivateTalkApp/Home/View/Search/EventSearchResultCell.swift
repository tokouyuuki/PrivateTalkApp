//
//  EventSearchResultCell.swift
//  PrivateTalkApp
//
//  Created by masashi.yamaguchi on 2025/03/12.
//

import SwiftUI

enum EventDateType {
    case allDay(start: Date)
    case startAndEnd(start: Date, end: Date)

    var startDate: Date {
        switch self {
        case .allDay(let start):
            return start
        case .startAndEnd(let start, _):
            return start
        }
    }
}

struct EventSearchResult {
    let id: String
    let dateType: EventDateType
    let title: String

    static var mock: EventSearchResult {
        .init(
//            dateType: .allDay(start: Date()),
            id: "sksksks",
            dateType: .startAndEnd(start: Date(), end: Date()),
            title: "春分の日"
        )
    }

    static var mockList: [EventSearchResult] {
        let randamInt = Int.random(in: 3...10)

        return (0..<randamInt).map { i in
                .init(
                    id: "\(i + 1000)",
                    dateType: .allDay(start: Date()),
                    title: "モックだよ \(i)"
                )
        }
    }
}

struct EventSearchResultCell: View {
    let result: EventSearchResult

    var body: some View {
        VStack(spacing: 8) {
            Text(result.dateType.startDate.eventResultDateString)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.gray.opacity(0.5)
                .frame(height: 1.5)

            HStack(spacing: 0) {
                Text(result.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    switch result.dateType {
                    case .allDay:
                        Text("終日")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.pink)

                    case .startAndEnd(let start, let end):
                        VStack(spacing: 4) {
                            Text(start.eventResultTimeString)
                                .font(.system(size: 12))
                                .foregroundStyle(.pink)

                            Text(end.eventResultTimeString)
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.leading, 16)
    }
}

#Preview {
    EventSearchResultCell(result: .mock)
}

extension Date {
    var eventResultDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy年MM月dd日・EEEE"

        return dateFormatter.string(from: self)
    }

    var eventResultTimeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "HH:mm"

        return dateFormatter.string(from: self)
    }
}
