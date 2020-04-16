import UIKit
import ThemeKit
import SnapKit

class LockScreenController: ThemeViewController {
    static let pageControlHeight: CGFloat = 28

    private let viewControllers: [UIViewController]

    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private let pageControl: BarPageControl

    private var currentIndex: Int?

    init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        pageControl = BarPageControl(barCount: viewControllers.count)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([viewControllers[0]], direction: .forward, animated: false)

        view.addSubview(pageViewController.view)
        pageViewController.view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        let pageControlBackground = UIView()

        view.addSubview(pageControlBackground)
        pageControlBackground.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        pageControlBackground.backgroundColor = .themeNavigationBarBackground

        let pageControlWrapper = UIView()

        view.addSubview(pageControlWrapper)
        pageControlWrapper.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
            maker.bottom.equalTo(pageControlBackground.snp.bottom)
            maker.height.equalTo(LockScreenController.pageControlHeight)
        }

        pageControlWrapper.addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

}

extension LockScreenController: UIPageViewControllerDataSource {

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = viewControllers.firstIndex(of: viewController), viewControllerIndex > 0 else { return nil }

        return viewControllers[viewControllerIndex - 1]
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = viewControllers.firstIndex(of: viewController), viewControllerIndex < (viewControllers.count - 1) else { return nil }

        return viewControllers[viewControllerIndex + 1]
    }

}

extension LockScreenController: UIPageViewControllerDelegate {

    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let controller = pendingViewControllers.first else {
            return
        }

        currentIndex = viewControllers.firstIndex(of: controller)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let index = currentIndex else {
            return
        }

        pageControl.currentPage = index
    }

}
