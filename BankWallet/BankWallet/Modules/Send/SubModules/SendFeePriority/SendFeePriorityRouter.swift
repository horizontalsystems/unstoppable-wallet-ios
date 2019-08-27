import UIKit

class SendFeePriorityRouter {
    weak var viewController: UIViewController?
}

extension SendFeePriorityRouter {

    static func module(coin: Coin) -> (UIView, ISendFeePriorityModule, ISendSubRouter)? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin) else {
            return nil
        }

        let router = SendFeePriorityRouter()
        let interactor = SendFeePriorityInteractor(provider: feeRateProvider)
        let presenter = SendFeePriorityPresenter(interactor: interactor, router: router, coin: coin, feeRatePriority: .medium)
        let view = SendFeePriorityView(delegate: presenter)

        presenter.view = view

        return (view, presenter, router)
    }

}

extension SendFeePriorityRouter: ISendFeePriorityRouter {

    func openPriorities(selected: FeeRatePriority, coin: Coin, priorityDelegate: IPriorityDelegate) {
        PriorityRouter.module(priorityDelegate: priorityDelegate, coin: coin, priority: selected).map { viewController in
            self.viewController?.present(viewController, animated: true)
        }
    }

}

extension SendFeePriorityRouter: ISendSubRouter {
}
