import Alamofire
import Foundation
import HsToolKit

extension NetworkManager {
    func fetch<T: Decodable>(
        url: URLConvertible, method: HTTPMethod = .get, parameters: Parameters = [:], encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil, interceptor: RequestInterceptor? = nil, responseCacherBehavior: ResponseCacher.Behavior? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await fetchData(
            url: url, method: method, parameters: parameters, encoding: encoding, headers: headers, interceptor: interceptor,
            responseCacherBehavior: responseCacherBehavior, contentTypes: ["application/json", "text/plain"]
        )

        return try decoder.decode(T.self, from: data)
    }
}
