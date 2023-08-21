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
    let errors: [Error]

    init(transactionData: TransactionData, additionalInfo: AdditionInfo?, warnings: [Warning], errors: [Error] = []) {
        self.transactionData = transactionData
        self.additionalInfo = additionalInfo
        self.warnings = warnings
        self.errors = errors
    }

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
        let chainName: String?
        let address: String?
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

        guard let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: evmKitWrapper.blockchainType,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
                evmKit: evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendData, coinServiceFactory: coinServiceFactory
        ) else {
            return nil
        }

        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let viewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let controller = SendEvmConfirmationViewController(mode: .send, transactionViewModel: viewModel, settingsViewModel: settingsViewModel)

        return controller
    }

    static func resendViewController(adapter: ITransactionsAdapter, type: ResendEvmTransactionType, transactionHash: String) throws -> UIViewController {
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
        guard let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: evmKitWrapper.blockchainType,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                coinManager: App.shared.coinManager
        ) else {
            throw CreateModuleError.cantCreateFeeRateProvider
        }

        let sendData: SendEvmData
        let gasLimit: Int?
        switch type {
        case .speedUp:
            let transactionData = TransactionData(to: to, value: value, input: input)
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil, warnings: [])
            gasLimit = transaction.gasLimit
        case .cancel:
            let transactionData = TransactionData(to: adapter.evmKit.receiveAddress, value: 0, input: Data())
            sendData = SendEvmData(transactionData: transactionData, additionalInfo: nil, warnings: [])
            gasLimit = nil
        }

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
                evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendData, coinServiceFactory: coinServiceFactory,
                previousTransaction: transaction, predefinedGasLimit: gasLimit
        ) else {
            throw CreateModuleError.cantCreateFeeSettingsModule
        }

        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let viewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)

        let mode: SendEvmConfirmationViewController.Mode
        switch type {
        case .speedUp: mode = .resend
        case .cancel: mode = .cancel
        }

        return SendEvmConfirmationViewController(mode: mode, transactionViewModel: viewModel, settingsViewModel: settingsViewModel)
    }

}

extension SendEvmConfirmationModule {

    enum CreateModuleError: LocalizedError {
        case wrongTransaction
        case cantCreateFeeRateProvider
        case cantCreateFeeSettingsModule
        case alreadyInBlock

        var errorDescription: String? {
            switch self {
            case .wrongTransaction, .cantCreateFeeRateProvider, .cantCreateFeeSettingsModule: return "alert.unknown_error".localized
            case .alreadyInBlock: return "tx_info.transaction.already_in_block".localized
            }
        }

    }

}

enum ResendEvmTransactionType {
    case speedUp
    case cancel
}
