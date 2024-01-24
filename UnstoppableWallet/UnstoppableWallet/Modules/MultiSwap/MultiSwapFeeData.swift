import EvmKit
import Foundation
import MarketKit
import SwiftUI

enum MultiSwapFeeData {
    case evm(gasPrice: GasPrice)
    case bitcoin(satoshiPerByte: Int)
}

enum MultiSwapFeeQuote {
    case evm(gasLimit: Int)
    case bitcoin(bytes: Int)
}

protocol IMultiSwapFeeService {
    var feeData: MultiSwapFeeData? { get }
    var modified: Bool { get }
    func sync() async throws
    func fee(quote: MultiSwapFeeQuote, token: Token) -> CoinValue?
    func settingsView() -> AnyView
}

class EvmMultiSwapFeeService: IMultiSwapFeeService {
    private let chain: Chain
    private let rpcSource: RpcSource
    private let networkManager = App.shared.networkManager

    private(set) var gasPrice: GasPrice?

    init?(blockchainType: BlockchainType) {
        guard let rpcSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)?.rpcSource else {
            return nil
        }

        chain = App.shared.evmBlockchainManager.chain(blockchainType: blockchainType)
        self.rpcSource = rpcSource
    }

    var feeData: MultiSwapFeeData? {
        guard let gasPrice else {
            return nil
        }

        return .evm(gasPrice: gasPrice)
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
