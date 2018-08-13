import Foundation
import RxSwift
import Alamofire
import ObjectMapper

enum ApiError: Error {
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

class ApiManager {
    private let apiUrl: String

    required init(apiUrl: String) {
        self.apiUrl = apiUrl
    }

    private func request(withMethod method: HTTPMethod, path: String, parameters: [String: Any]? = nil) -> URLRequestConvertible {
        let baseUrl = URL(string: apiUrl)!
        var request = URLRequest(url: baseUrl.appendingPathComponent(path))
        request.httpMethod = method.rawValue

        request.setValue("application/json", forHTTPHeaderField: "Accept")

//        print("API OUT: \(method.rawValue) \(apiUrl)\(path) \(parameters.map { String(describing: $0) } ?? "")")
        print("API OUT: \(method.rawValue) \(apiUrl)\(path)")

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

        return observable.do(onNext: { dataResponse in
            switch dataResponse.result {
            case .success(let result):
                print("API IN: SUCCESS: \(dataResponse.request?.url?.path ?? ""): response = \(result)")
//                print("API IN: SUCCESS: \(dataResponse.request?.url?.path ?? "")")
                ()
            case .failure:
                let data = dataResponse.data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0, options: .allowFragments)
                }

                print("API IN: ERROR: \(dataResponse.request?.url?.path ?? ""): status = \(dataResponse.response?.statusCode ?? 0), response: \(data.map { "\($0)" } ?? "nil")")
                ()
            }
        })

    }

    private func observable<T>(forRequest request: URLRequestConvertible, mapper: @escaping (Any) -> T?) -> Observable<T> {
        return self.observable(forRequest: request)
                .flatMap { dataResponse -> Observable<T> in
                    switch dataResponse.result {
                    case .success(let result):
                        if let value = mapper(result) {
                            return Observable.just(value)
                        } else {
                            return Observable.error(ApiError.mappingError)
                        }
                    case .failure:
                        if let response = dataResponse.response {
                            let data = dataResponse.data.flatMap { try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }
                            return Observable.error(ApiError.serverError(status: response.statusCode, data: data))
                        } else {
                            return Observable.error(ApiError.noConnection)
                        }
                    }
                }
    }

    func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<[T]> {
        return observable(forRequest: request, mapper: { json in
            if let jsonArray = json as? [[String: Any]] {
                return jsonArray.compactMap { try? T(JSONObject: $0) }
            }
            return nil
        })
    }

    func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<T> {
        return observable(forRequest: request, mapper: { json in
            if let jsonObject = json as? [String: Any], let object = try? T(JSONObject: jsonObject) {
                return object
            }
            return nil
        })
    }

}

extension ApiManager {

//    func getUnspentOutputs(addresses: [String]) -> Observable<[UnspentOutput]> {
//        let wrapperObservable: Observable<UnspentOutputsWrapper> = observable(forRequest: request(withMethod: .get, path: "/unspent", parameters: ["active": addresses.joined(separator: "|")]))
//        return wrapperObservable.map { $0.unspentOutputs }
//    }
//
//    func getTransactions(addresses: [String]) -> Observable<[BlockchainTransaction]> {
//        let wrapperObservable: Observable<TransactionsWrapper> = observable(forRequest: request(withMethod: .get, path: "/multiaddr", parameters: ["active": addresses.joined(separator: "|")]))
//        return wrapperObservable.map { $0.transactions }
//    }
//
//    func getExchangeRates() -> Observable<[String: Double]> {
//        return observable(forRequest: request(withMethod: .get, path: "/ticker"), mapper: { json in
//            if let hash = json as? [String: [String: Any]] {
//                var rates = [String: Double]()
//                for (currencyCode, data) in hash {
//                    rates[currencyCode] = (data["last"] as! Double)
//                }
//                return rates
//            }
//            return [:]
//        })
//    }

}
