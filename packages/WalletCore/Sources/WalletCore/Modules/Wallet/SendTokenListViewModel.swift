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
        case let .tokens(tokenAmounts):
            return items.filter { item in
                tokenAmounts.first(where: { $0.isSatisfy(token: item.wallet.token, balance: item.balance) }) != nil
            }
        }
    }

    var availableBlockchains: [Blockchain] {
        Array(Set(itemsWithOptions.map(\.wallet.token.blockchain))).sorted { $0.type.order < $1.type.order }
    }

    func itemState(searchText: String, blockchainFilter: BlockchainFilter?) -> ItemState {
        if items.isEmpty {
            return .loading
        }

        let text = searchText.trimmingCharacters(in: .whitespaces)
        var filtered = itemsWithOptions
        if !text.isEmpty {
            filtered = filtered.filter { item in
                item.wallet.token.coin.name.localizedCaseInsensitiveContains(text) || item.wallet.token.coin.code.localizedCaseInsensitiveContains(text)
            }
        }
        if let blockchain = blockchainFilter?.blockchain {
            filtered = filtered.filter { $0.wallet.token.blockchainType == blockchain.type }
        }

        return filtered.isEmpty ? .empty : .loaded(filtered)
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
    enum ItemState {
        case loading
        case empty
        case loaded([WalletListViewModel.Item])
    }
}

extension SendTokenListViewModel {
    enum BlockchainFilter: Hashable {
        case all
        case blockchain(Blockchain)

        var blockchain: Blockchain? {
            switch self {
            case let .blockchain(blockchain): return blockchain
            case .all: return nil
            }
        }
    }

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

        init(tokens: [TokenAmount], address: String? = nil, amount: AddressUri.Amount? = nil, memo: String? = nil) {
            filter = .tokens(tokens)
            self.address = address
            self.amount = amount
            self.memo = memo
        }

        struct TokenAmount: Hashable {
            let token: Token
            let amount: Decimal?

            init(token: Token, amount: Decimal? = nil) {
                self.token = token
                self.amount = amount
            }

            func isSatisfy(token: Token, balance: Decimal) -> Bool {
                guard self.token == token else {
                    return false
                }
                return balance >= (amount ?? 0)
            }
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
            case tokens([TokenAmount])

            var id: [String] {
                switch self {
                case let .blockchain(blockchainTypes, tokenTypes):
                    return (blockchainTypes?.map(\.uid) ?? []) + (tokenTypes?.map(\.id) ?? [])
                case let .tokens(tokenAmounts):
                    return tokenAmounts.map { "\($0.token.blockchain.uid):\($0.token.type.id)" }
                }
            }
        }
    }
}
