import Foundation
import RxSwift
import Alamofire
import ObjectMapper

class NetworkManager {

    private func single(forRequest request: URLRequestConvertible) -> Single<DataResponse<Any>> {
        let single = Single<DataResponse<Any>>.create { observer in
            let requestReference = Alamofire.request(request)
                    .validate()
                    .responseJSON(queue: DispatchQueue.global(qos: .background), completionHandler: { response in
                        observer(.success(response))
                    })

            return Disposables.create {
                requestReference.cancel()
            }
        }

        return single.do(onSuccess: { dataResponse in
            switch dataResponse.result {
            case .success(let result):
                Logger.instance.verbose("API IN: \(dataResponse.request?.url?.absoluteString ?? "nil")\n\(result)")
            case .failure:
                let data = dataResponse.data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0, options: .allowFragments)
                }

                Logger.instance.error("API IN: \(dataResponse.response?.statusCode ?? 0): \(dataResponse.request?.url?.absoluteString ?? "")\n\(data.map { "\($0)" } ?? "nil")")
            }
        })
    }

    private func single<T>(forRequest request: URLRequestConvertible, mapper: @escaping (Any) -> T?) -> Single<T> {
        return single(forRequest: request)
                .flatMap { dataResponse -> Single<T> in
                    switch dataResponse.result {
                    case .success(let result):
                        if let value = mapper(result) {
                            return Single.just(value)
                        } else {
                            return Single.error(NetworkError.mappingError)
                        }
                    case .failure:
                        if let response = dataResponse.response {
                            let data = dataResponse.data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }
                            return Single.error(NetworkError.serverError(status: response.statusCode, data: data))
                        } else {
                            return Single.error(NetworkError.noConnection)
                        }
                    }
                }
    }

}

extension NetworkManager {

    func single<T>(urlString: String, httpMethod: HTTPMethod, parameters: [String: Any]? = nil, timoutInterval: TimeInterval = 30, mapper: @escaping (Any) -> T?) -> Single<T> {
        guard let url = URL(string: urlString) else {
            return Single.error(NetworkError.invalidUrl)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.timeoutInterval = timoutInterval
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let request = Request(urlRequest: urlRequest, encoding: httpMethod == .get ? URLEncoding.default : JSONEncoding.default, parameters: parameters)

        return single(forRequest: request, mapper: mapper)
                .do(onSubscribe: {
                    Logger.instance.verbose("API OUT: \(httpMethod.rawValue) (\(timoutInterval)): \(url.absoluteString)\n\(parameters.map { "\($0 as AnyObject)" } ?? "")")
                })
    }

    func single<T: ImmutableMappable>(urlString: String, httpMethod: HTTPMethod, parameters: [String: Any]? = nil, timoutInterval: TimeInterval = 30) -> Single<T> {
        return single(urlString: urlString, httpMethod: httpMethod, parameters: parameters, timoutInterval: timoutInterval) { response -> T? in
            if let jsonObject = response as? [String: Any], let object = try? T(JSONObject: jsonObject) {
                return object
            }
            return nil
        }
    }

    func single<T>(urlString: String, httpMethod: HTTPMethod, parameters: [String: Any]? = nil, timoutInterval: TimeInterval = 30) -> Single<T> {
        return single(urlString: urlString, httpMethod: httpMethod, parameters: parameters, timoutInterval: timoutInterval) { response -> T? in
            if let object = response as? T {
                return object
            }
            return nil
        }
    }

}

extension NetworkManager {

    class Request: URLRequestConvertible {
        private let urlRequest: URLRequest
        private let encoding: ParameterEncoding
        private let parameters: [String: Any]?

        init(urlRequest: URLRequest, encoding: ParameterEncoding, parameters: [String: Any]?) {
            self.urlRequest = urlRequest
            self.encoding = encoding
            self.parameters = parameters
        }

        func asURLRequest() throws -> URLRequest {
            return try encoding.encode(urlRequest, with: parameters)
        }

    }

}

extension NetworkManager {

    enum NetworkError: Error {
        case invalidUrl
        case mappingError
        case noConnection
        case serverError(status: Int, data: Any?)
    }

}
