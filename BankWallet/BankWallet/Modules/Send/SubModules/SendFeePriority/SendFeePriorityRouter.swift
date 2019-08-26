import UIKit

class SendFeePriorityRouter {
    weak var mainRouter: ISendRouter?
    weak var priorityDelegate: IPriorityDelegate?

    func openPriorities(selected: FeeRatePriority) {
        mainRouter?.viewController?.present(PriorityRouter.module(priorityDelegate: priorityDelegate, priority: selected), animated: true)
    }

}

extension SendFeePriorityRouter {

    static func module(coin: Coin, mainRouter: ISendRouter) -> (UIView, ISendFeePriorityModule)? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin) else {
            return nil
        }

        let defaultPriority: FeeRatePriority = .medium
        let router = SendFeePriorityRouter()
        let interactor = SendFeePriorityInteractor(provider: feeRateProvider)
        let presenter = SendFeePriorityPresenter(interactor: interactor, router: router, feeRatePriority: defaultPriority)
        let view = SendFeePriorityView(delegate: presenter, feeRatePriority: defaultPriority)

        presenter.view = view
        router.mainRouter = mainRouter
        router.priorityDelegate = presenter

        return (view, presenter)
    }

}
