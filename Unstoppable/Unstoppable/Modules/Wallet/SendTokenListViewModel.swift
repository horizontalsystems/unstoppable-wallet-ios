import Combine
import Foundation
import MarketKit
import RxSwift

class SendTokenListViewModel: WalletListViewModel {
    let options: SendOptions

    init(options: SendOptions) {
        self.options = options

        super.init()
    }

    var itemsWithOptions: [WalletListViewModel.Item] {
        items.filter { item in
            if let blockchainTypes = options.blockchainTypes, !blockchainTypes.contains(item.wallet.token.blockchainType) {
                return false
            }
            if let tokenTypes = options.tokenTypes, !tokenTypes.contains(item.wallet.token.type) {
                return false
            }
            return true
        }
    }

    func humanReadableUri(amount: Decimal?, wallet: Wallet) -> Decimal? {
        guard let amount else {
            return nil
        }

        if wallet.token.blockchainType.isEvm { // convert amount from wei to human readable
            return amount.toReadable(decimals: wallet.token.decimals)
        }
        return amount
    }
}

extension SendTokenListViewModel {
    struct SendOptions: Identifiable {
        let blockchainTypes: [BlockchainType]?
        let tokenTypes: [TokenType]?
        let address: String?
        let amount: AddressUri.Amount?
        let memo: String?

        init(blockchainTypes: [BlockchainType]? = nil, tokenTypes: [TokenType]? = nil, address: String? = nil, amount: AddressUri.Amount? = nil, memo: String? = nil) {
            self.blockchainTypes = blockchainTypes
            self.tokenTypes = tokenTypes
            self.address = address
            self.amount = amount
            self.memo = memo
        }

        var id: String {
            var identifiers: [String] = blockchainTypes.map { $0.map(\.uid) } ?? []
            identifiers.append(contentsOf: tokenTypes.map { $0.map(\.id) } ?? [])
            identifiers.append(address ?? "")
            identifiers.append(amount?.description ?? "")
            identifiers.append(memo ?? "")

            return identifiers.joined(separator: "_")
        }
    }
}
