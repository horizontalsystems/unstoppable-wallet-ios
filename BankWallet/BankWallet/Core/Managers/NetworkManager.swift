import Foundation
import RxSwift
import Alamofire
import ObjectMapper

enum NetworkError: Error {
    case invalidRequest
    case mappingError
    case noConnection
    case serverError(status: Int, data: Any?)
}

class RequestRouter: URLRequestConvertible {
    private let request: URLRequest
    private let encoding: ParameterEncoding
    private let parameters: [String: Any]?

    init(request: URLRequest, encoding: ParameterEncoding, parameters: [String: Any]?) {
        self.request = request
        self.encoding = encoding
        self.parameters = parameters
    }

    func asURLRequest() throws -> URLRequest {
        return try encoding.encode(request, with: parameters)
    }

}

class NetworkManager {
    private let apiUrl: String

    required init(apiUrl: String) {
        self.apiUrl = apiUrl
    }

    private func request(withMethod method: HTTPMethod, path: String, parameters: [String: Any]? = nil) -> URLRequestConvertible {
        let baseUrl = URL(string: apiUrl)!
        var request = URLRequest(url: baseUrl.appendingPathComponent(path))
        request.httpMethod = method.rawValue

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return RequestRouter(request: request, encoding: method == .get ? URLEncoding.default : JSONEncoding.default, parameters: parameters)
    }

    private func observable(forRequest request: URLRequestConvertible) -> Observable<DataResponse<Any>> {
        let observable = Observable<DataResponse<Any>>.create { observer in
            let requestReference = Alamofire.request(request)
                    .validate()
                    .responseJSON(queue: DispatchQueue.global(qos: .background), completionHandler: { response in
                        observer.onNext(response)
                        observer.onCompleted()
                    })

            return Disposables.create {
                requestReference.cancel()
            }
        }

        return observable
    }

    private func observable<T>(forRequest request: URLRequestConvertible, mapper: @escaping (Any) -> T?) -> Observable<T> {
        return self.observable(forRequest: request)
                .flatMap { dataResponse -> Observable<T> in
                    switch dataResponse.result {
                    case .success(let result):
                        if let value = mapper(result) {
                            return Observable.just(value)
                        } else {
                            return Observable.error(NetworkError.mappingError)
                        }
                    case .failure:
                        if let response = dataResponse.response {
                            let data = dataResponse.data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }
                            return Observable.error(NetworkError.serverError(status: response.statusCode, data: data))
                        } else {
                            return Observable.error(NetworkError.noConnection)
                        }
                    }
                }
    }

    private func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<[T]> {
        return observable(forRequest: request, mapper: { json in
            if let jsonArray = json as? [[String: Any]] {
                return jsonArray.compactMap { try? T(JSONObject: $0) }
            }
            return nil
        })
    }

    private func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<T> {
        return observable(forRequest: request, mapper: { json in
            if let jsonObject = json as? [String: Any], let object = try? T(JSONObject: jsonObject) {
                return object
            }
            return nil
        })
    }

    private func observable<T>(forRequest request: URLRequestConvertible) -> Observable<T> {
        return observable(forRequest: request, mapper: { json in
            if let object = json as? T {
                return object
            }
            return nil
        })
    }

}

extension NetworkManager: IRateNetworkManager {

    func getLatestRate(coin: String, currencyCode: String) -> Observable<Double> {
        var coin = coin
        if coin.last == "t" || coin.last == "r" {
            coin.removeLast()
        }

        return observable(forRequest: request(withMethod: .get, path: "\(coin)/\(currencyCode)/index.json"))
    }

    func getRate(coin: String, currencyCode: String, year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Observable<Double> {
        var coin = coin
        if coin.last == "t" || coin.last == "r" {
            coin.removeLast()
        }

        return observable(forRequest: request(withMethod: .get, path: "\(coin)/\(currencyCode)/\(year)/\(month)/\(day)/\(hour)/\(minute)/index.json"))
    }

}
