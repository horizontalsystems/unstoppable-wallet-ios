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
        let presenter = SendFeePriorityPresenter(interactor: interactor, router: router, coin: coin)
        let view = SendFeePriorityView(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        return (view, presenter, router)
    }

}

extension SendFeePriorityRouter: ISendFeePriorityRouter {

    func openPriorities(items: [PriorityItem], onSelect: @escaping (PriorityItem) -> ()) {
        let alertController = AlertRouter.module(
                title: "send.tx_speed".localized,
                viewItems: items.map { item in
                    AlertViewItem(text: "\(item.priority.title) \((item.duration?.approximateHoursOrMinutes).map { "(< \($0))" }  ?? "")", selected: item.selected)
                }
        ) { index in
            onSelect(items[index])
        }

        viewController?.present(alertController, animated: true)
    }

}

extension SendFeePriorityRouter: ISendSubRouter {
}
