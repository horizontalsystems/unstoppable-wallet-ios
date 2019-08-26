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
        let presenter = SendFeePriorityPresenter(interactor: interactor, router: router, feeRatePriority: .medium)
        let view = SendFeePriorityView(delegate: presenter)

        presenter.view = view

        return (view, presenter, router)
    }

}

extension SendFeePriorityRouter: ISendFeePriorityRouter {

    func openPriorities(selected: FeeRatePriority, priorityDelegate: IPriorityDelegate) {
        viewController?.present(PriorityRouter.module(priorityDelegate: priorityDelegate, priority: selected), animated: true)
    }

}

extension SendFeePriorityRouter: ISendSubRouter {
}
