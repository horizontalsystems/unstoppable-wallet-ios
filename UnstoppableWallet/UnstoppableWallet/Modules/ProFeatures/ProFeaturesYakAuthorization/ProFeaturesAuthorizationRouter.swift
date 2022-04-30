import UIKit
import ComponentKit

class ProFeaturesAuthorizationRouter {
    private var service: ProFeaturesYakAuthorizationService
    private var visibleViewController: UIViewController

    init(service: ProFeaturesYakAuthorizationService, visibleViewController: UIViewController) {
        self.service = service
        self.visibleViewController = visibleViewController
    }

    private func showLoading() {
        HudHelper.instance.showSpinner()
    }

    private func showLockInfo(type: ProFeaturesStorage.NFTType) {
        let lockInfoViewController = ProFeaturesLockInfoViewController(config: .coinDetails) // Yak
        visibleViewController.present(lockInfoViewController, animated: true)
    }

    private func showSigner() {
        let lockInfoViewController = ProFeaturesLockInfoViewController(config: .coinDetails, delegate: self) // Signer Yak
        visibleViewController.present(lockInfoViewController, animated: true)
    }

}

extension ProFeaturesAuthorizationRouter: IProFeaturesSignDelegate {

    func onSign(sessionKey: String) {
        service.onReceive(sessionKey: sessionKey)
    }

}
