import Alamofire
import Foundation
import MarketKit
import ObjectMapper
import SwiftUI

class ThorChainMultiSwapProvider: IMultiSwapProvider {
    private let baseUrl = "https://thornode.ninerealms.com"

    private let networkManager = App.shared.networkManager
    private let marketKit = App.shared.marketKit
    private let storage: MultiSwapSettingStorage

    var assets = [Asset]()

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage

        syncPools()
    }

    var id: String {
        "thorchain"
    }

    var name: String {
        "THORChain"
    }

    var icon: String {
        "thorchain_32"
    }

    func supports(tokenIn: Token, tokenOut: Token) -> Bool {
        let tokens = assets.map(\.token)
        return tokens.contains(tokenIn) && tokens.contains(tokenOut)
    }

    func quote(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> IMultiSwapQuote {
        guard let assetIn = assets.first(where: { $0.token == tokenIn }) else {
            throw SwapError.unsupportedTokenIn
        }

        guard let assetOut = assets.first(where: { $0.token == tokenOut }) else {
            throw SwapError.unsupportedTokenOut
        }

        let amount = (amountIn * pow(10, 8)).rounded(decimal: 0)

        let destination: String

        switch tokenOut.blockchainType {
        case .avalanche, .binanceSmartChain, .ethereum: destination = "0xee50089786222df93f40899c0ee3d6a49e533266"
        case .bitcoinCash: destination = "qzawwkk57yuctdypj4azj5h9umtq4sy7xuev9fjs4d"
        case .bitcoin: destination = "bc1qhtn444838xzmfqv40g549e0x6c9vp83h65q3vy"
        case .litecoin: destination = "ltc1qhtn444838xzmfqv40g549e0x6c9vp83h7g6455"
        case .binanceChain: destination = "bnb1htn444838xzmfqv40g549e0x6c9vp83hw2pkf8"
        default: destination = ""
        }

        let parameters: Parameters = [
            "from_asset": assetIn.id,
            "to_asset": assetOut.id,
            "amount": amount.description,
            "destination": destination,
        ]

        let swapQuote: SwapQuote = try await networkManager.fetch(url: "\(baseUrl)/thorchain/quote/swap", parameters: parameters)

        return Quote(swapQuote: swapQuote)
    }

    func confirmationQuote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        fatalError("confirmationQuote(quote:tokenIn:tokenOut:amountIn:transactionSettings:) has not been implemented")
    }

    func settingsView(tokenIn _: Token, tokenOut _: Token, onChangeSettings _: @escaping () -> Void) -> AnyView {
        fatalError("settingsView(tokenIn:tokenOut:onChangeSettings:) has not been implemented")
    }

    func settingView(settingId _: String) -> AnyView {
        fatalError("settingView(settingId:) has not been implemented")
    }

    func preSwapView(step _: MultiSwapPreSwapStep, tokenIn _: Token, tokenOut _: Token, amount _: Decimal, isPresented _: Binding<Bool>, onSuccess _: @escaping () -> Void) -> AnyView {
        fatalError("preSwapView(step:tokenIn:tokenOut:amount:isPresented:onSuccess:) has not been implemented")
    }

    func swap(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, quote _: IMultiSwapConfirmationQuote) async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000) // todo
    }

    private func syncPools() {
        Task { [weak self, networkManager, baseUrl] in
            let pools: [Pool] = try await networkManager.fetch(url: "\(baseUrl)/thorchain/pools")
            self?.sync(pools: pools)
        }
    }

    private func sync(pools: [Pool]) {
        assets = []

        let availablePools = pools.filter { $0.status == "Available" }

        for pool in availablePools {
            let components = pool.asset.components(separatedBy: ".")

            guard let assetBlockchainId = components.first, let assetId = components.last else {
                continue
            }

            guard let blockchainType = blockchainType(assetBlockchainId: assetBlockchainId) else {
                continue
            }

            switch blockchainType {
            case .avalanche, .binanceSmartChain, .ethereum:
                let components = assetId.components(separatedBy: "-")

                let tokenType: TokenType

                if components.count == 2 {
                    tokenType = .eip20(address: components[1])
                } else {
                    tokenType = .native
                }

                let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: tokenType))

                if let token {
                    assets.append(Asset(id: pool.asset, token: token))
                }
            case .bitcoinCash, .bitcoin, .litecoin:
                let tokens = try? marketKit.tokens(queries: blockchainType.nativeTokenQueries)

                if let tokens {
                    assets.append(contentsOf: tokens.map { Asset(id: pool.asset, token: $0) })
                }
            case .binanceChain:
                let tokenType: TokenType

                if assetId == "BNB" {
                    tokenType = .native
                } else {
                    tokenType = .bep2(symbol: assetId)
                }

                let token = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: tokenType))

                if let token {
                    assets.append(Asset(id: pool.asset, token: token))
                }
            default: ()
            }
        }
    }

    private func blockchainType(assetBlockchainId: String) -> BlockchainType? {
        switch assetBlockchainId {
        case "AVAX": return .avalanche
        case "BCH": return .bitcoinCash
        case "BNB": return .binanceChain
        case "BSC": return .binanceSmartChain
        case "BTC": return .bitcoin
        case "ETH": return .ethereum
        case "LTC": return .litecoin
        default: return nil
        }
    }
}

extension ThorChainMultiSwapProvider {
    struct Asset {
        let id: String
        let token: Token
    }

    struct Pool: ImmutableMappable {
        let asset: String
        let status: String

        init(map: Map) throws {
            asset = try map.value("asset")
            status = try map.value("status")
        }
    }

    struct SwapQuote: ImmutableMappable {
        let expectedAmountOut: Decimal

        init(map: Map) throws {
            expectedAmountOut = try map.value("expected_amount_out", using: Transform.stringToDecimalTransform)
        }
    }

    enum SwapError: Error {
        case unsupportedTokenIn
        case unsupportedTokenOut
    }
}

extension ThorChainMultiSwapProvider {
    class Quote: IMultiSwapQuote {
        private let swapQuote: SwapQuote

        init(swapQuote: SwapQuote) {
            self.swapQuote = swapQuote
        }

        var amountOut: Decimal {
            swapQuote.expectedAmountOut / pow(10, 8)
        }

        var customButtonState: MultiSwapButtonState? {
            nil
        }

        var settingsModified: Bool {
            false
        }

        func fields(tokenIn _: Token, tokenOut _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
            []
        }

        func cautions() -> [CautionNew] {
            []
        }
    }
}
