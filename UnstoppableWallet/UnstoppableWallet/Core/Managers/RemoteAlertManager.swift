import UIKit
import HsToolKit
import RxSwift
import ObjectMapper
import Alamofire

class RemoteAlertManager {
    weak var notificationManager: INotificationManager?

    private let networkManager: NetworkManager
    private let appConfigProvider: IAppConfigProvider
    private let storage: IPriceAlertRequestStorage

    private let authDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let url: String
    private var jwtToken: String?

    init(networkManager: NetworkManager, reachabilityManager: IReachabilityManager, appConfigProvider: IAppConfigProvider, storage: IPriceAlertRequestStorage) {
        self.networkManager = networkManager
        self.appConfigProvider = appConfigProvider
        self.storage = storage

        self.url = appConfigProvider.pnsUrl

        reachabilityManager.reachabilityObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] isReachable in
                    if isReachable {
                        self?.schedule(requests: self?.storage.requests ?? [])
                    }
                })
                .disposed(by: disposeBag)
    }

    private func authenticate(after: Single<()>? = nil) -> Single<String> {
        let path = "identity/authenticate"
        let params = ["username": appConfigProvider.pnsUsername, "password": appConfigProvider.pnsPassword]
        let request = networkManager.session.request(url + path, parameters: params)

        return networkManager.single(request: request, mapper: AuthMapper())
                .do(onSuccess: { [weak self] token in
                    self?.jwtToken = token
                })
    }

    private func update(pushToken: String?, topics: [String], method: PriceAlertRequest.Method, restMethod: HTTPMethod) -> Single<()> {
        guard let pushToken = pushToken else {
            return .error(NotificationBackendError.token)
        }
        guard !topics.isEmpty else {
            return .just(())
        }

        let path = method.rawValue

        var params = [String: Any]()
        params["token"] = pushToken
        params["topics"] = topics
        params["bundle_id"] = Bundle.main.bundleIdentifier

        return wrapAuth(url: url + path, parameters: params, method: restMethod)
    }

    private func wrapAuth(url: String, parameters: [String: Any], method: HTTPMethod) -> Single<()> {
        let authSingle = authenticate()

        guard let jwtToken = jwtToken else {
            return authSingle.flatMap { [weak self] token in
                self?.makeRequest(url: url, parameters: parameters, jwtToken: token, method: method) ?? .error(NotificationBackendError.unknown)
            }
        }

        return makeRequest(url: url, parameters: parameters, jwtToken: jwtToken, method: method).catchError { error in
            if let error = error as? NotificationBackendError, error == .auth {
                return authSingle.flatMap { [weak self] token in
                    self?.makeRequest(url: url, parameters: parameters, jwtToken: token, method: method) ?? .error(NotificationBackendError.unknown)
                }
            }
            return .error(error)
        }
    }

    private func makeRequest(url: String, parameters: [String: Any], jwtToken: String, method: HTTPMethod) -> Single<()> {
        let request = networkManager.session.request(url, method: method, parameters: parameters, headers: ["Authorization": "Bearer " + jwtToken])

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

        return wrapAuth(url: url + path + "/" + pushToken, parameters: [:], method: .get)
    }

    func checkScheduledRequests() {
        schedule(requests: storage.requests)
    }

}
