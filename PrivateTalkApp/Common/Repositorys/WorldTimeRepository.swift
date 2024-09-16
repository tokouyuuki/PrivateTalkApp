//
//  WorldTimeRepository.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

final class WorldTimeRepository {
    
    private struct Constants {
        static let WORLD_TIME_API_URL = "https://worldtimeapi.org/api/timezone/Etc/UTC"
    }
    
    func fetchCurrentTime() async throws -> WorldTimeResponse {
        let response = try await NetworkService.shared.fetch(urlString: Constants.WORLD_TIME_API_URL,
                                                             decodeTo: WorldTimeResponse.self)
        
        return response
    }
}
