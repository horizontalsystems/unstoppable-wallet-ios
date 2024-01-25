import EvmKit
import Foundation
import MarketKit
import SwiftUI

enum MultiSwapTransactionSettings {
    case evm(gasPrice: GasPrice, nonce: Int)
    case bitcoin(satoshiPerByte: Int)
}

enum MultiSwapFeeQuote {
    case evm(gasLimit: Int)
    case bitcoin(bytes: Int)
}

protocol IMultiSwapTransactionService {
    var transactionSettings: MultiSwapTransactionSettings? { get }
    var modified: Bool { get }
    func sync() async throws
    func fee(quote: MultiSwapFeeQuote, token: Token) -> CoinValue?
    func settingsView() -> AnyView
}

class EvmMultiSwapTransactionService: IMultiSwapTransactionService {
    private let chain: Chain
    private let rpcSource: RpcSource
    private let networkManager = App.shared.networkManager

    private(set) var gasPrice: GasPrice?
    private(set) var nonce: Int?

    init?(blockchainType: BlockchainType) {
        guard let rpcSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            return nil
        }

        chain = App.shared.evmBlockchainManager.chain(blockchainType: blockchainType)
        self.rpcSource = rpcSource
    }

    var transactionSettings: MultiSwapTransactionSettings? {
        guard let gasPrice, let nonce else {
            return nil
        }

        return .evm(gasPrice: gasPrice, nonce: nonce)
    }

    var modified: Bool {
        true
    }

    func sync() async throws {
        if chain.isEIP1559Supported {
            gasPrice = try await EIP1559GasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        } else {
            gasPrice = try await LegacyGasPriceProvider.gasPrice(networkManager: networkManager, rpcSource: rpcSource)
        }

        nonce = 0
    }

    func fee(quote: MultiSwapFeeQuote, token: Token) -> CoinValue? {
        guard let gasPrice, case let .evm(gasLimit) = quote else {
            return nil
        }

        let amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, token.decimals)

        return CoinValue(kind: .token(token: token), value: amount)
    }

    func settingsView() -> AnyView {
        AnyView(ThemeNavigationView { EvmFeeSettingsModule.view() })
    }
}
