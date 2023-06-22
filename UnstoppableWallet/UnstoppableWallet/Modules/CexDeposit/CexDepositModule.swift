import UIKit

struct CexDepositModule {

    static func viewController(cexAsset: CexAsset, cexNetwork: CexNetwork) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        guard case .cex(let type) = account.type else {
            return nil
        }

        let provider = App.shared.cexProviderFactory.provider(type: type)

        let service = CexDepositService(cexAsset: cexAsset, cexNetwork: cexNetwork, provider: provider)
        let viewModel = CexDepositViewModel(service: service)
        return CexDepositViewController(viewModel: viewModel)
    }

}
