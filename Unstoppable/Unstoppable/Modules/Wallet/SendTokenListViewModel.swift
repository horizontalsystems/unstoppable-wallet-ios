import Combine
import Foundation
import MarketKit
import RxSwift
import WalletCore

class SendTokenListViewModel: WalletListViewModel {
    let options: SendOptions

    init(options: SendOptions) {
        self.options = options

        super.init()
    }

    var itemsWithOptions: [WalletListViewModel.Item] {
        guard let filter = options.filter else {
            return items
        }
        switch filter {
        case let .blockchain(blockchainTypes, tokenTypes):
            return items.filter { item in
                if let blockchainTypes, !blockchainTypes.contains(item.wallet.token.blockchainType) {
                    return false
                }
                if let tokenTypes, !tokenTypes.contains(item.wallet.token.type) {
                    return false
                }
                return true
            }
        case let .tokens(tokens):
            return items.filter { tokens.contains($0.wallet.token) }
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
    struct SendOptions: Identifiable, Hashable {
        let filter: Filter?
        let address: String?
        let amount: AddressUri.Amount?
        let memo: String?

        init(blockchainTypes: [BlockchainType]? = nil, tokenTypes: [TokenType]? = nil, address: String? = nil, amount: AddressUri.Amount? = nil, memo: String? = nil) {
            if blockchainTypes != nil || tokenTypes != nil {
                filter = .blockchain(blockchainTypes: blockchainTypes, tokenTypes: tokenTypes)
            } else {
                filter = nil
            }
            self.address = address
            self.amount = amount
            self.memo = memo
        }

        init(tokens: [Token], address: String? = nil, amount: AddressUri.Amount? = nil, memo: String? = nil) {
            filter = .tokens(tokens)
            self.address = address
            self.amount = amount
            self.memo = memo
        }

        var id: String {
            var identifiers: [String] = filter?.id ?? []
            identifiers.append(address ?? "")
            identifiers.append(amount?.description ?? "")
            identifiers.append(memo ?? "")
            return identifiers.joined(separator: "_")
        }

        enum Filter: Hashable {
            case blockchain(blockchainTypes: [BlockchainType]?, tokenTypes: [TokenType]?)
            case tokens([Token])

            var id: [String] {
                switch self {
                case let .blockchain(blockchainTypes, tokenTypes):
                    return (blockchainTypes?.map(\.uid) ?? []) + (tokenTypes?.map(\.id) ?? [])
                case let .tokens(tokens):
                    return tokens.map { "\($0.blockchain.uid):\($0.type.id)" }
                }
            }
        }
    }
}
