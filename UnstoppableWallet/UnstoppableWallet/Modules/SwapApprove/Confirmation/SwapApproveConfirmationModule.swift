import UIKit
import ThemeKit
import EvmKit
import BigInt
import HsExtensions

struct SwapApproveConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex, revokeAllowance: Bool = false, delegate: ISwapApproveDelegate?) -> UIViewController? {
        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: dex.blockchainType,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
                evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendData, coinServiceFactory: coinServiceFactory
        ) else {
            return nil
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

        guard let confirmationController = SwapApproveConfirmationModule.viewController(sendData: sendEvmData, dex: data.dex, revokeAllowance: true, delegate: delegate) else {
            return nil
        }

        return ThemeNavigationController(rootViewController: confirmationController)
    }


}
