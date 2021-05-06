import UIKit
import HsToolKit
import RxSwift
import ObjectMapper
import Alamofire

class RemoteAlertManager {
    weak var notificationManager: INotificationManager?

    private let networkManager: NetworkManager
    private let appConfigProvider: IAppConfigProvider
    private let jsonSerializer: ISerializer
    private let storage: IPriceAlertRequestStorage

    private let authDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let url: String
    private var jwtToken: String?

    init(networkManager: NetworkManager, reachabilityManager: IReachabilityManager, appConfigProvider: IAppConfigProvider, jsonSerializer: ISerializer, storage: IPriceAlertRequestStorage) {
        self.networkManager = networkManager
        self.appConfigProvider = appConfigProvider
        self.jsonSerializer = jsonSerializer
        self.storage = storage

        url = appConfigProvider.pnsUrl

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] isReachable in
                    if isReachable {
                        self?.schedule(requests: self?.storage.requests ?? [])
                    }
                })
                .disposed(by: disposeBag)
    }

    private func update(pushToken: String?, topics: [String], method: PriceAlertRequest.Method, restMethod: HTTPMethod) -> Single<()> {
        guard let pushToken = pushToken else {
            return .error(NotificationBackendError.token)
        }
        guard !topics.isEmpty else {
            return .just(())
        }

        let path = method.rawValue

        let deserializedTopics: [[String: Any]] = topics.compactMap { jsonSerializer.deserialize($0) }

        var params = [String: Any]()
        params["token"] = pushToken
        params["topics"] = deserializedTopics
        params["bundle_id"] = Bundle.main.bundleIdentifier

        return makeRequest(url: url + path, parameters: params, method: restMethod)
    }

    private func makeRequest(url: String, parameters: [String: Any], method: HTTPMethod) -> Single<()> {
        let request = networkManager.session.request(url, method: method, parameters: parameters, encoding: method == .post ? JSONEncoding.default : URLEncoding.default)

        return networkManager.single(request: request, mapper: SuccessMapper())
    }

}

extension RemoteAlertManager {

    class AuthMapper: IApiMapper {

        public func map(statusCode: Int, data: Any?) throws -> String {
            if statusCode > 400 {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            guard let map = data as? [String: Any], let authKey = map["token"] as? String else {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }

            return authKey
        }

    }

    class SuccessMapper: IApiMapper {

        public func map(statusCode: Int, data: Any?) throws {
            if statusCode == 403 {
                throw NotificationBackendError.auth
            }
            if statusCode > 400 {
                throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
            }
        }

    }

}

extension RemoteAlertManager: IRemoteAlertManager {

    func handle(requests: [PriceAlertRequest]) -> Observable<[()]> {
        let token = notificationManager?.token

        var subscribeTopics = [String]()
        var unsubscribeTopics = [String]()
        requests.forEach {
            switch $0.method {
            case .subscribe: subscribeTopics.append($0.topic)
            case .unsubscribe: unsubscribeTopics.append($0.topic)
            }
        }

        return Single.zip([
            update(pushToken: token, topics: subscribeTopics, method: .subscribe, restMethod: .post),
            update(pushToken: token, topics: unsubscribeTopics, method: .unsubscribe, restMethod: .post)
        ]).asObservable()
    }

    func schedule(requests: [PriceAlertRequest]) {
        handle(requests: requests)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onError: { [weak self] error in
                    self?.storage.save(requests: requests)
                }, onCompleted: { [weak self] in
                    self?.storage.delete(requests: requests)
                })
                .disposed(by: disposeBag)
    }

    func unsubscribeAll() -> Single<()> {
        guard let pushToken = notificationManager?.token else {
            return .error(NotificationBackendError.token)
        }

        let path = "pns/unsubscribeall"

        return makeRequest(url: url + path + "/" + pushToken, parameters: [:], method: .get)
    }

    func checkScheduledRequests() {
        schedule(requests: storage.requests)
    }

}
