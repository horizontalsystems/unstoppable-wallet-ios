import ComponentKit
import UIKit

enum CexDepositModule {
    static func viewController(cexAsset: CexAsset) -> UIViewController? {
        if cexAsset.depositNetworks.isEmpty {
            return viewController(cexAsset: cexAsset, network: nil)
        } else if cexAsset.depositNetworks.count == 1 {
            return viewController(cexAsset: cexAsset, network: cexAsset.depositNetworks[0])
        } else {
            return CexDepositNetworkSelectModule.viewController(cexAsset: cexAsset)
        }
    }

    static func viewController(cexAsset: CexAsset, network: CexDepositNetwork?) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case let .cex(cexAccount) = account.type else {
            return nil
        }

        let service = CexDepositService(cexAsset: cexAsset, network: network, provider: cexAccount.depositProvider)
        let viewItemFactory = CexDepositViewItemFactory()
        let viewModel = ReceiveAddressViewModel(service: service, viewItemFactory: viewItemFactory, decimalParser: AmountDecimalParser())

        return ReceiveAddressView(viewModel: viewModel).toViewController()
    }
}
