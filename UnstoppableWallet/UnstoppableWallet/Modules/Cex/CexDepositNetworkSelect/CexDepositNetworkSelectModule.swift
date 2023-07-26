import UIKit

struct CexDepositNetworkSelectModule {

    static func viewController(cexAsset: CexAsset) -> UIViewController {
        let service = CexDepositNetworkSelectService(cexAsset: cexAsset)
        let viewModel = CexDepositNetworkSelectViewModel(service: service)
        return CexDepositNetworkSelectViewController(viewModel: viewModel)
    }

}
