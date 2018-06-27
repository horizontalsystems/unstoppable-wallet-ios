import Foundation
import RxSwift
import Alamofire
import ObjectMapper
import BitcoinKit

enum NetworkError: Error {
    case invalidRequest
    case mappingError
    case noConnection
    case serverError(status: Int, data: Any?)
}

class RequestRouter: URLRequestConvertible {

    let request: URLRequest
    let encoding: ParameterEncoding
    let parameters: [String: Any]?

    init(request: URLRequest, encoding: ParameterEncoding, parameters: [String: Any]?) {
        self.request = request
        self.encoding = encoding
        self.parameters = parameters
    }

    public func asURLRequest() throws -> URLRequest {
        return try encoding.encode(request, with: parameters)
    }

}

class NetworkManager {
    let apiUrl: String

    required init(apiUrl: String) {
        self.apiUrl = apiUrl
    }

    func request(withMethod method: HTTPMethod, path: String, parameters: [String: Any]? = nil) -> URLRequestConvertible {
        let baseUrl = URL(string: apiUrl)!
        var request = URLRequest(url: baseUrl.appendingPathComponent(path))
        request.httpMethod = method.rawValue

        request.setValue("application/json", forHTTPHeaderField: "Accept")

//        logger?.log(tag: "HTTP", text: "HTTP OUT: \(method.rawValue) \(path) \(parameters.map { String(describing: $0) } ?? "")")

        return RequestRouter(request: request, encoding: method == .get ? URLEncoding.default : JSONEncoding.default, parameters: parameters)
    }

    func observable(forRequest request: URLRequestConvertible) -> Observable<DataResponse<Any>> {
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

        return observable.do(onNext: { [weak self] dataResponse in
            switch dataResponse.result {
            case .success(let result):
//                print("HTTP IN: SUCCESS: \(dataResponse.request?.url?.path ?? ""): response = \(result)")
                ()
            case .failure:
                let data = dataResponse.data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0, options: .allowFragments)
                }

//                print("HTTP IN: ERROR: \(dataResponse.request?.url?.path ?? ""): status = \(dataResponse.response?.statusCode ?? 0), response: \(data.map { "\($0)" } ?? "nil")")
                ()
            }
        })

    }

    func observable<T>(forRequest request: URLRequestConvertible, mapper: @escaping (Any) -> T?) -> Observable<T> {
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

    public func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<[T]> {
        return observable(forRequest: request, mapper: { json in
            if let jsonArray = json as? [[String: Any]] {
                return jsonArray.compactMap { try? T(JSONObject: $0) }
            }
            return nil
        })
    }

    public func observable<T: ImmutableMappable>(forRequest request: URLRequestConvertible) -> Observable<T> {
        return observable(forRequest: request, mapper: { json in
            if let jsonObject = json as? [String: Any], let object = try? T(JSONObject: jsonObject) {
                return object
            }
            return nil
        })
    }

}

extension NetworkManager: INetworkManager {
//    func getUnspentOutputs() -> Observable<[UnspentOutput]> {
//        let seed = Mnemonic.seed(mnemonic: Factory.instance.stubWalletDataProvider.walletData.words, passphrase: "")
//
//        let hdWallet = HDWallet(seed: seed, network: Network.testnet)
//
//        var addresses = [String]()
//
//        for i in 0...20 {
//            if let address = try? hdWallet.receiveAddress(index: UInt32(i)) {
//                print(String(describing: address))
//                addresses.append(String(describing: address))
//            }
//        }
//
//        for i in 0...20 {
//            if let address = try? hdWallet.changeAddress(index: UInt32(i)) {
//                addresses.append(String(describing: address))
//            }
//        }
//
//        let wrapper: Observable<WrapperUnspentOutput> = observable(forRequest: request(withMethod: .get, path: "/unspent", parameters: ["active": addresses.joined(separator: "|")]))
//        return wrapper.map { $0.outputs }
//    }
//
//    func getExchangeRates() -> Observable<[String: Double]> {
//        return Observable.just(["BTC": 14400])
//    }

//    func addressesData(forAddresses addresses: [String]) -> Observable<AddressesData> {
//        return observable(forRequest: request(withMethod: .get, path: "/multiaddr", parameters: ["active": addresses.joined(separator: "|")]))
//    }

}
