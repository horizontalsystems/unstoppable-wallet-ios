import SnapKit
import UIKit

class HUDView: UIViewController, HUDViewInterface {
    let presenter: HUDViewPresenterInterface
    var config: HUDViewModel
    var window: UIWindow?
    var backgroundWindow: BackgroundHUDWindow
    var holderView: UIView? { window }
    let statusBarStyle: UIStatusBarStyle?

    let containerView: HUDContainerView

    var keyboardNotificationHandler: HUDKeyboardHelper? {
        didSet {
            keyboardNotificationHandler?.delegate = self
        }
    }

    var visibleKeyboardOffset: CGFloat = 0

    public var showCompletion: (() -> Void)?
    public var dismissCompletion: (() -> Void)?

    init(presenter: HUDViewPresenterInterface, config: HUDViewModel, backgroundWindow: BackgroundHUDWindow, containerView: HUDContainerView, statusBarStyle: UIStatusBarStyle? = nil) {
        self.presenter = presenter
        self.config = config
        self.backgroundWindow = backgroundWindow
        self.containerView = containerView
        self.statusBarStyle = statusBarStyle

        super.init(nibName: nil, bundle: Bundle(for: HUDView.self))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(containerView)
        presenter.viewDidLoad()
    }

    func place() {
        place(holderView: holderView)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        window?.clipsToBounds = true
        visibleKeyboardOffset = 0
        coordinator.animate(alongsideTransition: { _ in
            self.place(holderView: self.holderView)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.window?.clipsToBounds = false
        })
    }

    func set(config: HUDConfig) {
        self.config = config

        backgroundWindow.set(transparent: config.userInteractionEnabled)
        presenter.updateCover()
    }

    func adjustPlace() {
        UIView.animate(withDuration: config.inAnimationDuration, delay: 0, options: config.animationCurve, animations: {
            self.place(holderView: self.holderView)
        })
    }

    func place(holderView: UIView?) {
        view.layoutIfNeeded()

        holderView?.frame.size = containerView.frame.size
        switch config.style {
        case .center: adjustViewCenter(for: holderView)
        case let .banner(style): adjustViewCenter(for: holderView, style: style)
        }
    }

    func adjustViewCenter(for _: UIView?, style: HUDBannerStyle? = nil) {
        guard let style else {
            set(CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2), for: holderView, useConstraints: false)
            return
        }

        let screenCenter = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        let contentCenter = CGPoint(x: containerView.frame.size.width / 2, y: containerView.frame.size.height / 2)

        let centerOffset = config.absoluteInsetsValue ? config.hudInset : safeCorrectedOffset(for: config.hudInset, style: style, relativeWindow: false)

        let viewCenter: CGPoint
        switch style {
        case .top:
            viewCenter = CGPoint(x: screenCenter.x + centerOffset.x, y: contentCenter.y + centerOffset.y)
        case .left:
            viewCenter = CGPoint(x: contentCenter.x + centerOffset.x, y: screenCenter.y + centerOffset.y)
        case .bottom:
            viewCenter = CGPoint(x: screenCenter.x + centerOffset.x, y: UIScreen.main.bounds.height - contentCenter.y + centerOffset.y)
        case .right:
            viewCenter = CGPoint(x: UIScreen.main.bounds.width - contentCenter.x + centerOffset.x, y: screenCenter.y + centerOffset.y)
        }

        set(viewCenter, for: holderView, useConstraints: false)
    }

    func set(_ center: CGPoint, for view: UIView?, useConstraints: Bool) {
        if config.handleKeyboard == .none {
            visibleKeyboardOffset = 0
        } else if let view {
            let viewBottom = center.y + view.frame.height / 2
            visibleKeyboardOffset = keyboardNotificationHandler?.calculateKeyboardOffset(startOffset: visibleKeyboardOffset, viewBottom: viewBottom, onlyOnShow: config.handleKeyboard == .startPosition) ?? 0
        }
        let keyboardCorrectedCenter = CGPoint(x: center.x, y: center.y + visibleKeyboardOffset)

        if useConstraints {
            view?.snp.remakeConstraints { maker in
                maker.center.equalTo(keyboardCorrectedCenter)
            }
        } else {
            view?.center = keyboardCorrectedCenter
        }
    }

    func safeCorrectedOffset(for inset: CGPoint, style: HUDBannerStyle?, relativeWindow: Bool) -> CGPoint {
        var correctedOffset: CGPoint = .zero
        if #available(iOS 11.0, *), let style {
            let insets = view.safeAreaInsets
            switch style {
            case .top:
                correctedOffset.y = inset.y + insets.top
                correctedOffset.x = relativeWindow ? 0 : inset.x
            case .bottom:
                correctedOffset.y = -inset.y - insets.bottom
                correctedOffset.x = relativeWindow ? 0 : inset.x
            case .left:
                correctedOffset.x = inset.x + insets.left
                correctedOffset.y = relativeWindow ? 0 : inset.y
            case .right:
                correctedOffset.x = -inset.x - insets.right
                correctedOffset.y = relativeWindow ? 0 : inset.y
            }
        }
        return correctedOffset
    }

    deinit {
//        print("deinit viewController \(self)")
    }
}

extension HUDView {
    func hide(animated: Bool, completion: (() -> Void)? = nil) {
        presenter.dismiss(animated: animated, completion: completion)
    }
}

extension HUDView {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.supportedInterfaceOrientations
        } else {
            return UIInterfaceOrientationMask.allButUpsideDown
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let style = statusBarStyle {
            return style
        }

        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.preferredStatusBarStyle
        }
        return presentingViewController?.preferredStatusBarStyle ?? UIApplication.shared.statusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.prefersStatusBarHidden
        }
        return presentingViewController?.prefersStatusBarHidden ?? UIApplication.shared.isStatusBarHidden
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.preferredStatusBarUpdateAnimation
        } else {
            return .none
        }
    }

    override var shouldAutorotate: Bool {
        if let rootViewController = UIApplication.shared.delegate?.window??.rootViewController {
            return rootViewController.shouldAutorotate
        } else {
            return true
        }
    }
}

extension HUDView: HUDKeyboardHelperDelegate {
    func keyboardDidChangePosition() {
        place(holderView: holderView)
    }
}
