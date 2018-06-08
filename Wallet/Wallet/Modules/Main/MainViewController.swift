import UIKit

class MainViewController: UITabBarController {

    let viewDelegate: MainViewDelegate

    init(viewDelegate: MainViewDelegate, viewControllers: [UIViewController]) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: MainViewController.self), bundle: nil)

        self.viewControllers = viewControllers
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.barStyle = .black
        tabBar.tintColor = .walletOrange
        tabBar.unselectedItemTintColor = UIColor(hex: 0x8a8a8f)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}
