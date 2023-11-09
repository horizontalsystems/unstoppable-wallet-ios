import UIKit
import UIExtensions
import SnapKit

class ActionSheetPresentationController: UIPresentationController {
    private let tapView = ActionSheetTapView()
    private let configuration: ActionSheetConfiguration
    private var driver: TransitionDriver?

    init(driver: TransitionDriver?, presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, configuration: ActionSheetConfiguration) {
        self.driver = driver
        self.configuration = configuration
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        if configuration.tapToDismiss {
            tapView.handleTap = { [weak presentedViewController] in
                presentedViewController?.dismiss(animated: true)
            }
        }
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        guard let presentedView = presentedView else {
            return
        }
        containerView?.addSubview(tapView)
        containerView?.addSubview(presentedView)

        tapView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        switch configuration.style {
        case .alert:
            presentedView.alpha = 0
            presentedView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        case .sheet:
            presentedView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(containerView!.snp.bottom)
            }
            containerView?.layoutIfNeeded()
        }

        tapView.backgroundColor = configuration.coverBackgroundColor
        tapView.alpha = 0

        alongsideTransition { [weak self] in
            self?.tapView.alpha = 1
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)

        if completed {
            driver?.direction = .dismiss
        } else {
            self.tapView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        delegate?.presentationControllerWillDismiss?(self)

        alongsideTransition { [weak self] in
            self?.tapView.alpha = 0
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)

        if completed {
            delegate?.presentationControllerDidDismiss?(self)
            self.tapView.removeFromSuperview()
        }
    }
    
    private func alongsideTransition(_ action: @escaping () -> Void) {
        guard let coordinator = self.presentedViewController.transitionCoordinator else {
            action()
            return
        }

        coordinator.animate(alongsideTransition: { (_) in
            action()
        }, completion: nil)
    }

}
