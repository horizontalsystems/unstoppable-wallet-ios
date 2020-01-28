import UIKit
import ThemeKit

class MainViewController: ThemeTabBarController {

    let viewDelegate: IMainViewDelegate

    init(viewDelegate: IMainViewDelegate, viewControllers: [UIViewController], selectedIndex: Int) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: MainViewController.self), bundle: nil)

        self.viewControllers = viewControllers

        self.selectedIndex = selectedIndex
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewDelegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .themeDefault
    }

}

extension MainViewController: IMainView {
}
