import UIKit
import WalletKit

class SettingsViewController: UIViewController {

    let viewDelegate: SettingsViewDelegate

    init(viewDelegate: SettingsViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: SettingsViewController.self), bundle: nil)

        tabBarItem = UITabBarItem(title: "settings.tab_bar_item".localized, image: UIImage(named: "settings.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func logout() {
        WordsManager.shared.removeWords()

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let viewController = GuestRouter.module()

        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        })
    }

    @IBAction func showRealmInfo() {
        WalletKitManager.shared.showRealmInfo()
    }

    @IBAction func connectToPeer() {
        do {
            try WalletKitManager.shared.start()
        } catch {
            print("Could not start: \(error)")
        }
    }

}
