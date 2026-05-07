import UIExtensions
import UIKit

public protocol IHudMode {
    var id: Int { get }
    var icon: UIImage? { get }
    var iconColor: UIColor { get }
    var title: String? { get }
    var loadingState: Float? { get }
}

public class HUD {
    public static let instance = HUD()

    let keyboardNotificationHandler: HUDKeyboardHelper

    public var config: HUDConfig
    var view: HUDView?

    public var animated: Bool = true
    private(set) var tag: String = ""

    init(config: HUDConfig? = nil, keyboardNotifications: HUDKeyboardHelper = .shared) {
        self.config = config ?? HUDConfig()
        keyboardNotificationHandler = keyboardNotifications
    }

    public func show(error: String?) {
        HUDStatusFactory.instance.config.dismissTimeInterval = 2
        let content = HUDStatusFactory.instance.view(type: .error, title: error)
        showHUD(content, onTapHUD: { hud in
            hud.hide()
        })
    }

    public func showHUD(_ content: UIView & HUDContentViewInterface, statusBarStyle: UIStatusBarStyle? = nil, animated: Bool = true, showCompletion: (() -> Void)? = nil, dismissCompletion: (() -> Void)? = nil, onTapCoverView: ((HUD) -> Void)? = nil, onTapHUD: ((HUD) -> Void)? = nil) {
        self.animated = animated

        let maxSize = CGSize(width: UIScreen.main.bounds.width * config.allowedMaximumSize.width, height: UIScreen.main.bounds.height * config.allowedMaximumSize.height)

        if let view {
            view.set(config: config)

            view.containerView.setContent(content: content, preferredSize: config.preferredSize, maxSize: maxSize, exact: config.exactSize)
            view.adjustPlace()
        } else { // if it's no view, create new and show
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let coverWindow = DimHUDWindow(windowScene: scene, config: config)
                coverWindow.set(transparent: config.userInteractionEnabled)

                coverWindow.onTap = { [weak self] in
                    if let weakSelf = self {
                        onTapCoverView?(weakSelf)
                    }
                }

                let containerView = HUDContainerView(withModel: config)
                containerView.onTapContainer = { [weak self] in
                    if let weakSelf = self {
                        onTapHUD?(weakSelf)
                    }
                }
                containerView.isHidden = true
                containerView.setContent(content: content, preferredSize: config.preferredSize, maxSize: maxSize, exact: config.exactSize)

                view = HUD.create(config: config, router: self, backgroundWindow: coverWindow, containerView: containerView, statusBarStyle: statusBarStyle)
                view?.keyboardNotificationHandler = keyboardNotificationHandler

                if content.actions.firstIndex(where: { $0.type == .show }) == nil {
                    show()
                }
            }
        }
        view?.presenter.addActionTimers(content.actions)
        view?.showCompletion = showCompletion
        view?.dismissCompletion = dismissCompletion
    }
}

extension HUD: HUDViewRouterInterface {
    class func create(config: HUDConfig, router: HUDViewRouterInterface, backgroundWindow: BackgroundHUDWindow, containerView: HUDContainerView, statusBarStyle: UIStatusBarStyle? = nil) -> HUDView {
        let interactor: HUDViewInteractorInterface = HUDViewInteractor()
        let presenter: HUDViewPresenterInterface & HUDViewInteractorDelegate = HUDViewPresenter(interactor: interactor, router: router, coverView: backgroundWindow.coverView, containerView: containerView, config: config)
        let view = HUDView(presenter: presenter, config: config, backgroundWindow: backgroundWindow, containerView: containerView, statusBarStyle: statusBarStyle)

        presenter.feedbackGenerator = HapticGenerator.instance
        presenter.view = view
        interactor.delegate = presenter

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let window = HUDWindow(windowScene: scene, rootController: view)
            view.window = window
        }

        view.place()

        return view
    }

    public func show(config: HUDConfig, viewItem: ViewItem, statusBarStyle: UIStatusBarStyle? = nil, forced: Bool = false) {
        self.config = config
        tag = viewItem.tag
        let showBlock = { [weak self] in
            let contentView = TopHUDContentView()
            contentView.title = viewItem.title
            contentView.icon = viewItem.icon
            contentView.iconColor = viewItem.iconColor
            contentView.isLoading = viewItem.isLoading

            if let showingTime = viewItem.showingTime {
                contentView.actions.append(HUDTimeAction(type: .dismiss, interval: showingTime))
            }

            self?.showHUD(contentView, statusBarStyle: statusBarStyle, onTapHUD: { hud in
                hud.hide()
            })
        }

        if forced, let view {
            view.hide(animated: true) {
                showBlock()
            }
        } else {
            showBlock()
        }
    }

    public func show() {
        view?.presenter.show(animated: animated, completion: { [weak view] in
            view?.showCompletion?()
        })
    }

    public func hide() {
        view?.presenter.dismiss(animated: animated, completion: { [weak view, weak self] in
            view?.dismissCompletion?()
            self?.view = nil
        })
    }
}

public extension HUD {
    struct ViewItem {
        let icon: UIImage?
        let iconColor: UIColor
        let title: String?
        let showingTime: TimeInterval?
        let isLoading: Bool

        let tag: String

        public init(icon: UIImage?, iconColor: UIColor, title: String?, tag: String = "", showingTime: TimeInterval? = 2, isLoading: Bool = false) {
            self.icon = icon
            self.iconColor = iconColor
            self.title = title
            self.tag = tag
            self.showingTime = showingTime
            self.isLoading = isLoading
        }
    }
}
