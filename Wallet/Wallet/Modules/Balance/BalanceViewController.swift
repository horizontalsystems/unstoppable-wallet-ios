import UIKit

class BalanceViewController: UIViewController {

    let viewDelegate: BalanceViewDelegate

    init(viewDelegate: BalanceViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BalanceViewController.self), bundle: nil)

        tabBarItem = UITabBarItem(title: "Balance", image: UIImage(named: "balance.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}
