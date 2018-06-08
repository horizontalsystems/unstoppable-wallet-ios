import UIKit

class TransactionsViewController: UIViewController {

    let viewDelegate: TransactionsViewDelegate

    init(viewDelegate: TransactionsViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: TransactionsViewController.self), bundle: nil)

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "transactions.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}
