import BigInt
import EvmKit
import HsExtensions
import MarketKit
import ThemeKit
import UIKit

enum SwapApproveConfirmationModule {
    static func viewController(sendData: SendEvmData, blockchainType: BlockchainType, revokeAllowance: Bool = false, delegate: ISwapApproveDelegate?) throws -> UIViewController {
        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            throw CreateError.noEvmKit
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: blockchainType,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            coinManager: App.shared.coinManager
        ) else {
            throw CreateError.cantFoundBaseToken
        }

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
            evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendData, coinServiceFactory: coinServiceFactory
        ) else {
            throw CreateError.wrongGasPriceService
        }

        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)

        if revokeAllowance {
            return SwapRevokeConfirmationViewController(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel, delegate: delegate)
        }
        return SwapApproveConfirmationViewController(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel, delegate: delegate)
    }

    static func revokeViewController(data: SwapAllowanceService.ApproveData, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let eip20Adapter = App.shared.adapterManager.adapter(for: data.token) as? Eip20Adapter else {
            return nil
        }

        let service = SwapApproveService(
            eip20Kit: eip20Adapter.eip20Kit,
            amount: BigUInt(data.amount.hs.roundedString(decimal: data.token.decimals)) ?? 0,
            spenderAddress: data.spenderAddress,
            allowance: 0
        )

        guard case let .approveAllowed(sendData) = service.state else {
            return nil
        }
        let sendEvmData = SendEvmData(transactionData: sendData, additionalInfo: nil, warnings: [])

        guard let confirmationController = try? SwapApproveConfirmationModule.viewController(sendData: sendEvmData, blockchainType: data.dex.blockchainType, revokeAllowance: true, delegate: delegate) else {
            return nil
        }

        return ThemeNavigationController(rootViewController: confirmationController)
    }

    enum CreateError: LocalizedError {
        case noEvmKit
        case cantFoundBaseToken
        case wrongGasPriceService

        var errorDescription: String? {
            switch self {
            case .noEvmKit: return "Can't create EvmKit!"
            case .cantFoundBaseToken: return "Can't found token for fee payments!"
            case .wrongGasPriceService: return "Can't create service for calculating Gas Price!"
            }
        }
    }
}
