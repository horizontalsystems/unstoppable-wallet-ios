import UIKit

class MainViewController: UITabBarController {

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

        tabBar.shadowImage = UIImage()
        let separator = UIView(frame: CGRect(x: 0, y: 0, width: 10000, height: 1 / UIScreen.main.scale))
        separator.backgroundColor = AppTheme.tabBarSeparatorColor
        tabBar.addSubview(separator)

        tabBar.barTintColor = .clear
        tabBar.backgroundImage = UIImage(color: AppTheme.navigationBarBackgroundColor)

        tabBar.tintColor = .appJacob
        tabBar.unselectedItemTintColor = .appGray

        viewDelegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        App.theme.statusBarStyle
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBar.superview?.setNeedsLayout()
    }
}

extension MainViewController: IMainView {
}
