import UIKit

class LockScreenController: UIPageViewController {
    private let controllers: [UIViewController]

    init(viewControllers: [UIViewController]) {
        controllers = viewControllers
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)

        guard let initialViewController = viewControllers.first else {
            fatalError("PageViewController must has at least one initial controller")
        }
        setViewControllers([initialViewController], direction: .forward, animated: true)
        dataSource = self

        modalPresentationStyle = .fullScreen
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        GradientLayer.appendLayer(to: view, fromColor: AppTheme.controllerBackgroundFromGradient, toColor: AppTheme.controllerBackgroundToGradient)

        // Set pageIndicatorTintColor and currentPageIndicatorTintColor
        // only for the following stack of UIViewControllers
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = .appSteel20
        pageControl.currentPageIndicatorTintColor = App.theme.colorJacob
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return App.theme.statusBarStyle
    }

}

extension LockScreenController: UIPageViewControllerDataSource {

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = controllers.firstIndex(of: viewController), viewControllerIndex > 0 else { return nil }

        return controllers[viewControllerIndex - 1]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = controllers.firstIndex(of: viewController), viewControllerIndex < (controllers.count - 1) else { return nil }

        return controllers[viewControllerIndex + 1]
    }

    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return controllers.count
    }

    public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = controllers.first,
              let firstViewControllerIndex = controllers.firstIndex(of: firstViewController) else {
            return 0
        }

        return firstViewControllerIndex
    }

}
