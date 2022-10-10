import Foundation
import UIKit
import ThemeKit
import EvmKit
import MarketKit
import HsExtensions

struct SendEvmData {
    let transactionData: TransactionData
    let additionalInfo: AdditionInfo?
    let warnings: [Warning]

    enum AdditionInfo {
        case otherDApp(info: DAppInfo)
        case send(info: SendInfo)
        case uniswap(info: SwapInfo)
        case oneInchSwap(info: OneInchSwapInfo)

        var dAppInfo: DAppInfo? {
            if case .otherDApp(let info) = self { return info } else { return nil }
        }

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
        let assetShortMetadata: NftAssetShortMetadata?

        init(domain: String?, assetShortMetadata: NftAssetShortMetadata? = nil) {
            self.domain = domain
            self.assetShortMetadata = assetShortMetadata
        }
    }

    struct DAppInfo {
        let name: String?
    }

    struct SwapInfo {
        let estimatedOut: Decimal
        let estimatedIn: Decimal
        let slippage: String?
        let deadline: String?
        let recipientDomain: String?
        let price: String?
        let priceImpact: UniswapModule.PriceImpactViewItem?
    }

    struct OneInchSwapInfo {
        let tokenFrom: Token
        let tokenTo: Token
        let amountFrom: Decimal
        let estimatedAmountTo: Decimal
        let slippage: Decimal
        let recipient: Address?
    }

}

struct SendEvmConfirmationModule {
    private static let forceMultiplier: Double = 1.2

    static func viewController(evmKitWrapper: EvmKitWrapper, sendData: SendEvmData) -> UIViewController? {
        let evmKit = evmKitWrapper.evmKit

        guard let coinServiceFactory = EvmCoinServiceFactory(blockchainType: evmKitWrapper.blockchainType, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            return nil
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKit)
        let gasDataService = EvmCommonGasDataService.instance(evmKit: evmKit, blockchainType: evmKitWrapper.blockchainType, gasLimitSurchargePercent: sendData.transactionData.input.isEmpty ? 0 : 20)
        let feeService = EvmFeeService(evmKit: evmKit, gasPriceService: gasPriceService, gasDataService: gasDataService, transactionData: sendData.transactionData)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, evmLabelManager: App.shared.evmLabelManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager)
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        let controller = SendEvmConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)

        return controller
    }

    static func resendViewController(adapter: ITransactionsAdapter, action: TransactionInfoModule.Option, transactionHash: String) throws -> UIViewController {
        guard let adapter = adapter as? EvmTransactionsAdapter, let fullTransaction = adapter.evmKit.transaction(hash: Data(hex: transactionHash.hs.stripHexPrefix())) else {
            throw CreateModuleError.wrongTransaction
        }

        let transaction = fullTransaction.transaction

        guard let value = transaction.value, let input = transaction.input, let to = transaction.to else {
            throw CreateModuleError.wrongTransaction
        }

        guard transaction.blockNumber == nil else {
            throw CreateModuleError.alreadyInBlock
        }

        let evmKitWrapper = adapter.evmKitWrapper
        guard let coinServiceFactory = EvmCoinServiceFactory(blockchainType: evmKitWrapper.blockchainType, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            throw CreateModuleError.cantCreateFeeRateProvider
        }

        let sendData: SendEvmData
        switch action {
        case .speedUp:
            let transactionData = TransactionData(to: to, value: value, input: input, nonce: transaction.nonce)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil, warnings: [])
        case .cancel:
            let transactionData = TransactionData(to: adapter.evmKit.receiveAddress, value: 0, input: Data(), nonce: transaction.nonce)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil, warnings: [])
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit, previousTransaction: transaction)
        let gasDataService = EvmCommonGasDataService.instance(evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, gasLimit: transaction.gasLimit)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, gasDataService: gasDataService, transactionData: sendData.transactionData)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, evmLabelManager: App.shared.evmLabelManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager)
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

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
