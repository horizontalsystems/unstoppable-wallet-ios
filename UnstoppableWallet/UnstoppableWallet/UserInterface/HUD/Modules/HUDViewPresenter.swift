import Foundation

class HUDViewPresenter: HUDViewPresenterInterface, HUDViewInteractorDelegate, CoverViewDelegate {
    let interactor: HUDViewInteractorInterface
    let router: HUDViewRouterInterface
    var feedbackGenerator: HUDFeedbackGenerator?

    weak var view: HUDViewInterface?

    var coverView: CoverViewInterface
    var containerView: HUDContainerInterface
    public let config: HUDConfig

    private var timers = [Timer]()

    init(interactor: HUDViewInteractorInterface, router: HUDViewRouterInterface, coverView: CoverViewInterface, containerView: HUDContainerInterface, config: HUDConfig) {
        self.interactor = interactor
        self.router = router
        self.coverView = coverView
        self.containerView = containerView
        self.config = config

        self.coverView.delegate = self
    }

    func viewDidLoad() {}

    func updateCover() {
        if coverView.transparent {
            coverView.hide(animated: true, completion: nil)
        } else {
            coverView.show(animated: true)
        }
    }

    func showContainerView(animated: Bool = true, completion: (() -> Void)? = nil) {
        var style: HUDBannerStyle?
        if case let .banner(bannerStyle) = config.style {
            style = bannerStyle
        }
        let correctedOffset = containerView.outScreenOffset(for: config.absoluteInsetsValue ? config.hudInset : view?.safeCorrectedOffset(for: config.hudInset, style: style, relativeWindow: true) ?? .zero, style: style)
        containerView.show(animated: true, appearStyle: config.appearStyle, offset: correctedOffset, completion: completion)
    }

    func show(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let hapticType = config.hapticType {
            feedbackGenerator?.notification(hapticType)
        }
        updateCover()
        showContainerView(animated: animated, completion: completion)
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        removeAllTimers()

        var style: HUDBannerStyle?
        if case let .banner(bannerStyle) = config.style {
            style = bannerStyle
        }
        let correctedOffset = containerView.outScreenOffset(for: config.absoluteInsetsValue ? config.hudInset : view?.safeCorrectedOffset(for: config.hudInset, style: style, relativeWindow: true) ?? .zero, style: style)
        containerView.hide(animated: animated, appearStyle: config.appearStyle, offset: correctedOffset, completion: { [weak self] in
            self?.completeDismiss(completion: completion)
        })
        coverView.hide(animated: animated, completion: { [weak self] in
            self?.completeDismiss(completion: completion)
        })
    }

    func completeDismiss(completion: (() -> Void)? = nil) {
        if !(containerView.isVisible || (coverView.isVisible ?? false)) {
            router.view?.window = nil
            router.view = nil
            completion?()
        }
    }

    func addActionTimers(_ timeActions: [HUDTimeAction]) {
        removeAllTimers()
        timeActions.forEach { [weak self] timeAction in
            var prepareAction: (() -> Void)? = nil

            switch timeAction.type {
            case .show: prepareAction = { [weak self] in self?.router.show() }
            case .dismiss: prepareAction = { [weak self] in self?.router.hide() }
            case .custom: prepareAction = nil
            }
            self?.timers.append(ActionTimer.scheduledMainThreadTimer(action: {
                prepareAction?()
                timeAction.action?()
            }, interval: timeAction.interval))
        }
    }

    func removeAllTimers() {
        for timer in timers {
            timer.invalidate()
        }
        timers.removeAll()
    }

    // CoverView delegate

    func didHide() {}

    deinit {
//        print("Deinit HUDView presenter \(self)")
    }
}
