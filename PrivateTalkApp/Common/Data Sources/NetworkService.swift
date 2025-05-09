//
//  NetworkService.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

// MARK: - ネットワーク通信
struct NetworkService {
    
    func fetch<T: Decodable>(urlString: String, decodeTo type: T.Type) async throws(NetworkError) -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.badUrlError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // レスポンスが返ってきているかのチェック
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noResponse
            }
            
            // レスポンスステータスコードが200番台以外の場合
            if httpResponse.statusCode != 200 {
                if [400, 404, 500, 502, 503, 504].contains(httpResponse.statusCode) {
                    throw NetworkError.httpResponseError(statusCode: httpResponse.statusCode)
                } else {
                    throw NetworkError.httpResponseError(statusCode: nil)
                }
            }
            
            let decodeData = try JSONDecoder().decode(T.self, from: data)
            return decodeData
            
        } catch let urlError as URLError {
            throw NetworkError.urlError(errorCode: urlError.code)
        } catch is DecodingError {
            throw NetworkError.decodingError
        } catch {
            throw NetworkError.unexpected
        }
    }
}
