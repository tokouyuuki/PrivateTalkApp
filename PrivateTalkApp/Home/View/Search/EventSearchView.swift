//
//  EventSearchView.swift
//  PrivateTalkApp
//
//  Created by masashi.yamaguchi on 2025/03/12.
//

import SwiftUI

struct EventSearchRepository {
    func search(_ text: String) async throws -> [EventSearchResult] {
//        try? await Task.sleep(nanoseconds: 1_000_000_000 * 2)
        return EventSearchResult.mockList
    }
}

@MainActor
@Observable
final class EventSearchViewModel {
    private let repository: EventSearchRepository = .init()

    private(set) var text: String = ""
    private(set) var result: [EventSearchResult] = []

    func onChangedText(_ text: String) {
        if text.isEmpty {
            result = []
            self.text = ""
            return
        }

        Task {
            let result = try? await repository.search(text)
            self.result = result ?? []
            self.text = text
        }
    }
}

struct EventSearchView: View {
    @State private var viewModel: EventSearchViewModel = .init()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(viewModel.result, id: \.id) { result in
                    EventSearchResultCell(result: result)
                }
            }
        }
        .searchable(text: .init(get: { viewModel.text }, set: viewModel.onChangedText))
    }
}

#Preview {
    NavigationStack {
        EventSearchView()
    }
}
