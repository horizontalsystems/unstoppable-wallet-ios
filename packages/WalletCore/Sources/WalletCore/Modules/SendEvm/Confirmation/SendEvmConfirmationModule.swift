import EvmKit
import Foundation
import HsExtensions
import MarketKit

import UIKit

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
            if case let .otherDApp(info) = self { return info } else { return nil }
        }

        var sendInfo: SendInfo? {
            if case let .send(info) = self { return info } else { return nil }
        }

        var swapInfo: SwapInfo? {
            if case let .uniswap(info) = self { return info } else { return nil }
        }

        var oneInchSwapInfo: OneInchSwapInfo? {
            if case let .oneInchSwap(info) = self { return info } else { return nil }
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

enum SendEvmConfirmationModule {
    static func viewController(evmKitWrapper: EvmKitWrapper, sendData: SendEvmData) -> UIViewController? {
        let evmKit = evmKitWrapper.evmKit

        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: evmKitWrapper.blockchainType,
            marketKit: Core.shared.marketKit,
            currencyManager: Core.shared.currencyManager,
            coinManager: Core.shared.coinManager
        ) else {
            return nil
        }

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
            evmKit: evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendData, coinServiceFactory: coinServiceFactory
        ) else {
            return nil
        }

        let service = SendEvmTransactionService(sendData: sendData, privateSendMode: .none, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: Core.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: Core.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let viewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: Core.shared.evmLabelManager, contactLabelService: contactLabelService)
        let controller = SendEvmConfirmationViewController(mode: .send, transactionViewModel: viewModel, settingsViewModel: settingsViewModel)

        return controller
    }
}
