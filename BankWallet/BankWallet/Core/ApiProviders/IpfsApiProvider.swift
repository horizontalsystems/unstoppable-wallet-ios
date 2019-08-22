import Foundation
import RxSwift

class IpfsApiProvider: IIpfsApiProvider {
    private let timeoutInterval: TimeInterval = 10
    private let lastTimeoutInterval: TimeInterval = 60

    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    public func gatewaysSingle<T>(singleProvider: @escaping (String, TimeInterval) -> Single<T>) -> Single<T> {
        let gateways = appConfigProvider.ipfsGateways
        return gatewaySingle(gateways: gateways, singleProvider: singleProvider)
    }

    private func gatewaySingle<T>(gateways: [String], singleProvider: @escaping (String, TimeInterval) -> Single<T>) -> Single<T> {
        guard let gateway = gateways.first else {
            return Single.error(IpfsApiError.allGatewaysReturnedError)
        }

        let baseUrlString = "\(gateway)/ipns/\(appConfigProvider.ipfsId)"

        let leftGateways = Array(gateways.dropFirst())

        let timeout = leftGateways.isEmpty ? lastTimeoutInterval : timeoutInterval

        return singleProvider(baseUrlString, timeout).catchError { [unowned self] _ in
            return self.gatewaySingle(gateways: leftGateways, singleProvider: singleProvider)
        }
    }

}

extension IpfsApiProvider {

    enum IpfsApiError: Error {
        case allGatewaysReturnedError
    }

}
