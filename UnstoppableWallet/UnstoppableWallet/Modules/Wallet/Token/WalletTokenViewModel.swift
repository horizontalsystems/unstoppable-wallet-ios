import Combine
import Foundation
import MarketKit

class WalletTokenViewModel {
    private let service: WalletTokenService

    init(service: WalletTokenService) {
        self.service = service
    }

}

extension WalletTokenViewModel {

    var title: String {
        var title = service.coinName
        if let badge = service.badge {
            title += " (\(badge))"
        }
        return title
    }

}
