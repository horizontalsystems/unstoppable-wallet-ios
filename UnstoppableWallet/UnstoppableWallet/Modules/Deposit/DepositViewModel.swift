import UIKit
import MarketKit

class DepositViewModel {
    private let service: DepositService

    init(service: DepositService) {
        self.service = service
    }

}

extension DepositViewModel {

    var coin: Coin {
        service.coin
    }

    var placeholderImageName: String {
        service.token.placeholderImageName
    }

    var address: String {
        service.address
    }

    var watchAccount: Bool {
        service.watchAccount
    }

    var isMainNet: Bool {
        service.isMainNet
    }

    var additionalInfo: String? {
        var items = [String]()

        if let derivation = service.mnemonicDerivation {
            items.append(derivation.addressType)
        }

        if !service.isMainNet {
            items.append("TestNet")
        }

        if items.isEmpty {
            return nil
        } else {
            return items.joined(separator: ", ")
        }
    }

}
