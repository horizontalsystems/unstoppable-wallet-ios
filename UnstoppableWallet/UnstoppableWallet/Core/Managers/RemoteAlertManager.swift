import UIKit
import HsToolKit
import RxSwift
import ObjectMapper
import Alamofire

class RemoteAlertManager {
    weak var notificationManager: INotificationManager?

    private let networkManager: NetworkManager
    private let appConfigProvider: IAppConfigProvider

    private let authDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let url: String
    private var jwtToken: String?

    enum Method: String {
        case subscribe = "pns/subscribe"
        case unsubscribe = "pns/unsubscribe"
    }

    init(networkManager: NetworkManager, appConfigProvider: IAppConfigProvider) {
        self.networkManager = networkManager
        self.appConfigProvider = appConfigProvider

        self.url = appConfigProvider.pnsUrl
    }

    private func composePriceTopic(alert: PriceAlert) -> String {
        "\(alert.coin.code)_24hour_\(alert.state.rawValue)percent"
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

    private func update(pushToken: String?, topics: [String], method: Method) -> Single<()> {
        guard let pushToken = pushToken else {
            return .error(NotificationBackendError.token)
        }

        let path = method.rawValue
        let params: [String: Any] = ["token": pushToken, "topics": topics]

        return wrapAuth(url: url + path, parameters: params)
    }

    private func wrapAuth(url: String, parameters: [String: Any]) -> Single<()> {
        let authSingle = authenticate()

        guard let jwtToken = jwtToken else {
            return authSingle.flatMap { [weak self] token in
                self?.makeRequest(url: url, parameters: parameters, jwtToken: token) ?? .error(NotificationBackendError.unknown)
            }
        }

        return makeRequest(url: url, parameters: parameters, jwtToken: jwtToken).catchError { error in
            if let error = error as? NotificationBackendError, error == .auth {
                return authSingle.flatMap { [weak self] token in
                    self?.makeRequest(url: url, parameters: parameters, jwtToken: token) ?? .error(NotificationBackendError.unknown)
                }
            }
            return .error(error)
        }
    }

    private func makeRequest(url: String, parameters: [String: Any], jwtToken: String) -> Single<()> {
        let request = networkManager.session.request(url, method: .post, parameters: parameters, headers: ["Authorization": "Bearer " + jwtToken])

        return networkManager.single(request: request, mapper: SuccessMapper())
    }

}

extension RemoteAlertManager {

    class AuthMapper: IApiMapper {

        public func map(statusCode: Int, data: Any?) throws -> String {
            if statusCode > 400 {
                throw NotificationBackendError.unknown
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
                throw NotificationBackendError.unknown
            }
        }

    }

}

extension RemoteAlertManager: IRemoteAlertManager {

    func handle(newAlerts: [PriceAlert]) -> Single<()> {
        let topics = newAlerts.map(composePriceTopic)
        return update(pushToken: notificationManager?.token, topics: topics, method: .subscribe)
    }

    func handle(deletedAlerts: [PriceAlert]) -> Single<()> {
        let topics = deletedAlerts.map(composePriceTopic)
        return update(pushToken: notificationManager?.token, topics: topics, method: .unsubscribe)
    }

}
