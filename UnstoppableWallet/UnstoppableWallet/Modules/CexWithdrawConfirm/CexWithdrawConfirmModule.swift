import Foundation
import UIKit
import ComponentKit

struct CexWithdrawConfirmModule {

    static func viewController(sendData: CexWithdrawModule.SendData) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        let provider = App.shared.cexProviderFactory.provider(type: type)
        let contactLabelService = sendData.network?.blockchain.map {
            ContactLabelService(contactManager: App.shared.contactManager, blockchainType: $0.type)
        }

        let service = CexWithdrawConfirmService(sendData: sendData, provider: provider)
        let coinService = CexCoinService(cexAsset: sendData.cexAsset, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let viewModel = CexWithdrawConfirmViewModel(service: service, coinService: coinService, contactLabelService: contactLabelService)
        return CexWithdrawConfirmViewController(viewModel: viewModel, cex: type.cex)
    }

}
