import UIKit

class MainViewController: UITabBarController {

    let viewDelegate: IMainViewDelegate

    init(viewDelegate: IMainViewDelegate, viewControllers: [UIViewController]) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: MainViewController.self), bundle: nil)

        self.viewControllers = viewControllers
        self.viewControllers?.forEach {
            ($0 as? UINavigationController)?.view.layoutIfNeeded()
            _ = ($0 as? UINavigationController)?.viewControllers.first?.view
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBar.barStyle = AppTheme.tabBarStyle
        tabBar.tintColor = .cryptoYellow
        tabBar.unselectedItemTintColor = .cryptoGray
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension MainViewController: IMainView {
}
