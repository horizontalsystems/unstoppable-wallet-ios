import UIKit

class WalletViewController: UIViewController {

    let viewDelegate: WalletViewDelegate

    init(viewDelegate: WalletViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: WalletViewController.self), bundle: nil)

        tabBarItem = UITabBarItem(title: "Balance", image: UIImage(named: "balance.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Balance"
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}
