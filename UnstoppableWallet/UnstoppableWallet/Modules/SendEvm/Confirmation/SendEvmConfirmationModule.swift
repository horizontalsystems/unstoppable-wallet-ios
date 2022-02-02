import Foundation
import UIKit
import ThemeKit
import EthereumKit
import MarketKit

struct SendEvmData {
    let transactionData: TransactionData
    let additionalInfo: AdditionInfo?

    enum AdditionInfo {
        case send(info: SendInfo)
        case uniswap(info: SwapInfo)
        case oneInchSwap(info: OneInchSwapInfo)

        var sendInfo: SendInfo? {
            if case .send(let info) = self { return info } else { return nil }
        }

        var swapInfo: SwapInfo? {
            if case .uniswap(let info) = self { return info } else { return nil }
        }

        var oneInchSwapInfo: OneInchSwapInfo? {
            if case .oneInchSwap(let info) = self { return info } else { return nil }
        }
    }

    struct SendInfo {
        let domain: String?
    }

    struct SwapInfo {
        let estimatedOut: Decimal
        let estimatedIn: Decimal
        let slippage: String?
        let deadline: String?
        let recipientDomain: String?
        let price: String?
        let priceImpact: UniswapModule.PriceImpactViewItem?
        let warning: String?
    }

    struct OneInchSwapInfo {
        let platformCoinFrom: PlatformCoin
        let platformCoinTo: PlatformCoin
        let amountFrom: Decimal
        let estimatedAmountTo: Decimal
        let slippage: Decimal
        let recipient: Address?
    }

}

struct SendEvmConfirmationModule {
    private static let forceMultiplier: Double = 1.2

    private static func platformCoin(networkType: NetworkType) -> PlatformCoin? {
        switch networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: return try? App.shared.marketKit.platformCoin(coinType: .ethereum)
        case .bscMainNet: return try? App.shared.marketKit.platformCoin(coinType: .binanceSmartChain)
        }
    }

    static func viewController(evmKitWrapper: EvmKitWrapper, sendData: SendEvmData) -> UIViewController? {
        guard let platformCoin = platformCoin(networkType: evmKitWrapper.evmKit.networkType),
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let gasPriceService = LegacyGasPriceService(evmKit: evmKitWrapper.evmKit, feeRateProvider: feeRateProvider)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: sendData.transactionData)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EvmFeeViewModel(service: feeService, coinService: coinServiceFactory.baseCoinService)

        let controller = SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)

        return controller
    }

    static func resendViewController(adapter: ITransactionsAdapter, action: TransactionInfoModule.Option, transactionHash: String) throws -> UIViewController {
        guard let adapter = adapter as? EvmTransactionsAdapter,
              let fullTransaction = adapter.evmKit.transaction(hash: Data(hex: transactionHash.stripHexPrefix())),
              let toAddress = fullTransaction.transaction.to else {
            throw CreateModuleError.wrongTransaction
        }

        guard fullTransaction.receiptWithLogs == nil else {
            throw CreateModuleError.alreadyInBlock
        }

        let gasPrice = fullTransaction.transaction.gasPrice
        let feeRange = gasPrice...(4 * gasPrice)
        
        guard let platformCoin = platformCoin(networkType: adapter.evmKit.networkType),
              let feeRateProvider = App.shared.feeRateProviderFactory.forcedProvider(coinType: platformCoin.coinType, customFeeRange: feeRange, multiply: Self.forceMultiplier) else {
            throw CreateModuleError.cantCreateFeeRateProvider
        }

        let sendData: SendEvmData
        switch action {
        case .speedUp:
            let tx = fullTransaction.transaction
            let transactionData = TransactionData(to: toAddress, value: tx.value, input: tx.input, nonce: tx.nonce)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil)
        case .cancel:
            let tx = fullTransaction.transaction
            let transactionData = TransactionData(to: adapter.evmKit.receiveAddress, value: 0, input: Data(), nonce: tx.nonce)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil)
        }

        let evmKitWrapper = adapter.evmKitWrapper
        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let gasPriceService = LegacyGasPriceService(evmKit: evmKitWrapper.evmKit, feeRateProvider: feeRateProvider)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: sendData.transactionData)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EvmFeeViewModel(service: feeService, coinService: coinServiceFactory.baseCoinService)

        let viewController = SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
        viewController.confirmationTitle = action.confirmTitle
        viewController.confirmationButtonTitle = action.confirmButtonTitle
        viewController.topDescription = action.description

        return viewController
    }

}

extension SendEvmConfirmationModule {

    enum CreateModuleError: LocalizedError {
        case wrongTransaction
        case cantCreateFeeRateProvider
        case alreadyInBlock

        var errorDescription: String? {
            switch self {
            case .wrongTransaction, .cantCreateFeeRateProvider: return "alert.unknown_error".localized
            case .alreadyInBlock: return "tx_info.transaction.already_in_block".localized
            }
        }

    }

}