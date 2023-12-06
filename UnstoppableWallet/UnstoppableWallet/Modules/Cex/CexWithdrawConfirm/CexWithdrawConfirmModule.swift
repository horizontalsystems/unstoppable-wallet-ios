import ComponentKit
import Foundation
import UIKit

enum CexWithdrawConfirmModule {
    static func viewController(sendData: CexWithdrawModule.SendData) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case let .cex(cexAccount) = account.type else {
            return nil
        }

        let contactLabelService = sendData.network?.blockchain.map {
            ContactLabelService(contactManager: App.shared.contactManager, blockchainType: $0.type)
        }

        let handler = cexAccount.withdrawHandler
        let service = CexWithdrawConfirmService(sendData: sendData, handler: handler)
        let coinService = CexCoinService(cexAsset: sendData.cexAsset, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let viewModel = CexWithdrawConfirmViewModel(service: service, coinService: coinService, contactLabelService: contactLabelService)
        return CexWithdrawConfirmViewController(viewModel: viewModel, handler: handler)
    }
}
