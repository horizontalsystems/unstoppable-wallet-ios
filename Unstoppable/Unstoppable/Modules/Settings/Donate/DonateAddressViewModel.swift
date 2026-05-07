import Foundation
import MarketKit

class DonateAddressViewModel: ObservableObject {
    private let marketKit = Core.shared.marketKit
    @Published var viewItems: [ViewItem]

    init() {
        guard let blockchains = try? marketKit.allBlockchains() else {
            viewItems = []
            return
        }

        var viewItems = [ViewItem]()
        for (type, address) in AppConfig.donationAddresses {
            if let blockchain = blockchains.first(where: { $0.type == type }) {
                viewItems.append(.init(name: blockchain.name, type: type, address: address))
            }
        }

        self.viewItems = viewItems
    }
}

extension DonateAddressViewModel {
    struct ViewItem: Identifiable {
        let name: String
        let type: BlockchainType
        let address: String

        var id: String {
            name + type.uid + address
        }
    }
}
