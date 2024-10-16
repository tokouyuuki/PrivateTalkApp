//
//  NetworkService.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

// MARK: - ネットワーク通信
struct NetworkService {
    
    func fetch<T: Decodable>(urlString: String, decodeTo type: T.Type) async throws(PrivateTalkAppError) -> T {
        guard let url = URL(string: urlString) else {
            throw PrivateTalkAppError.networkError(.badUrlError)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // レスポンスが返ってきているかのチェック
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PrivateTalkAppError.networkError(.noResponse)
            }
            
            // レスポンスステータスコードが200番台以外の場合
            if httpResponse.statusCode != 200 {
                if [400, 404, 500, 502, 503, 504].contains(httpResponse.statusCode) {
                    throw PrivateTalkAppError.networkError(.httpResponseError(statusCode: httpResponse.statusCode))
                } else {
                    throw PrivateTalkAppError.networkError(.httpResponseError(statusCode: nil))
                }
            }
            
            let decodeData = try JSONDecoder().decode(T.self, from: data)
            return decodeData
            
        } catch let urlError as URLError {
            throw PrivateTalkAppError.networkError(.urlError(urlError.code))
        } catch is DecodingError {
            throw PrivateTalkAppError.networkError(.decodingError)
        } catch {
            throw PrivateTalkAppError.unexpected
        }
    }
}
