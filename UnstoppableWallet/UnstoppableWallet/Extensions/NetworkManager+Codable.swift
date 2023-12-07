import Foundation
import Alamofire
import HsToolKit
import ObjectMapper

extension NetworkManager {

    public func fetch<T: Decodable>(
            url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default,
            headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil,
            context: MapContext? = nil
    ) async throws -> T {
        let data = try await fetchData(
                url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor,
                responseCacherBehavior: responseCacherBehavior
        )

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    public func fetchArray<T: Decodable>(
            url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default,
            headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil,
            context: MapContext? = nil
    ) async throws -> [T] {
        let data = try await fetchData(
                url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor,
                responseCacherBehavior: responseCacherBehavior
        )

        let decoder = JSONDecoder()
        return try decoder.decode([T].self, from: data)
    }
}
