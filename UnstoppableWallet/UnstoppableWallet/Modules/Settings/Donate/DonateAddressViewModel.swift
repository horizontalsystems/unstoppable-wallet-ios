import Foundation
import MarketKit

class DonateAddressViewModel {
    typealias ViewItem = (String, BlockchainType, String)

    let viewItems: [ViewItem]

    init(marketKit: MarketKit.Kit) {
        guard let blockchains = try? marketKit.allBlockchains() else {
            viewItems = []
            return
        }

        var viewItems = [ViewItem]()
        for (type, address) in AppConfig.donationAddresses {
            if let blockchain = blockchains.first(where: { $0.type == type }) {
                viewItems.append((blockchain.name, type, address))
            }
        }

        self.viewItems = viewItems
    }
}
