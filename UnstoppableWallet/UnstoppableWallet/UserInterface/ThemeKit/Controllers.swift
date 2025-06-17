import UIExtensions
import UIKit

extension ThemeNavigationController: IDeinitDelegate {}
extension ThemeTabBarController: IDeinitDelegate {}
extension ThemeViewController: IDeinitDelegate {}

open class ThemeNavigationController: UINavigationController {
    public var onDeinit: (() -> Void)?

    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    private func commonInit() {
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = .themeGray
    }

    deinit {
        onDeinit?()
    }

    override open var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    override open var childForStatusBarHidden: UIViewController? {
        topViewController
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        topViewController?.preferredStatusBarStyle ?? .themeDefault
    }

    override open var prefersStatusBarHidden: Bool {
        topViewController?.prefersStatusBarHidden ?? false
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationItem.searchController != nil {
            DispatchQueue.main.async {
                self.navigationBar.sizeToFit()
            }
        }
    }
}

open class ThemeTabBarController: UITabBarController {
    public var onDeinit: (() -> Void)?

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        onDeinit?()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        tabBar.barTintColor = .themeBlade
        tabBar.tintColor = .themeJacob
        tabBar.unselectedItemTintColor = .themeGray

        updateUITheme()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tabBar.superview?.setNeedsLayout()
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        .themeDefault
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUITheme()
    }

    private func updateUITheme() {
        tabBar.isTranslucent = true
        tabBar.backgroundImage = UIImage(color: .themeTabBarBackground)
        tabBar.backgroundColor = .themeTabBarBackground
    }
}

open class ThemeViewController: UIViewController {
    public var onDeinit: (() -> Void)?

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        onDeinit?()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeTyler
        navigationItem.largeTitleDisplayMode = .never
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        .themeDefault
    }
}
