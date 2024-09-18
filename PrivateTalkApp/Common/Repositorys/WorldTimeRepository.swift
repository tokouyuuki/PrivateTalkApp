//
//  WorldTimeRepository.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

struct WorldTimeRepository {
    
    private struct Constants {
        static let WORLD_TIME_API_URL = "https://worldtimeapi.org/api/timezone/Etc/UTC"
    }
    
    private let networkService = NetworkService()
    
    func fetchCurrentTime() async throws -> WorldTimeResponse {
        
        return try await networkService.fetch(urlString: Constants.WORLD_TIME_API_URL,
                                                     decodeTo: WorldTimeResponse.self)
    }
}
