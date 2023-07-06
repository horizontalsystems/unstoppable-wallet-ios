import Foundation
import UIKit
import ComponentKit

struct CexWithdrawConfirmModule {

    static func viewController(cexAsset: CexAsset, network: CexWithdrawNetwork?, address: String, amount: Decimal) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        let provider = App.shared.cexProviderFactory.provider(type: type)
        let contactLabelService = network?.blockchain.map {
            ContactLabelService(contactManager: App.shared.contactManager, blockchainType: $0.type)
        }

        let service = CexWithdrawConfirmService(cexAsset: cexAsset, network: network, address: address, amount: amount, provider: provider)
        let viewModel = CexWithdrawConfirmViewModel(service: service, contactLabelService: contactLabelService)
        return CexWithdrawConfirmViewController(viewModel: viewModel, cex: type.cex)
    }

}
