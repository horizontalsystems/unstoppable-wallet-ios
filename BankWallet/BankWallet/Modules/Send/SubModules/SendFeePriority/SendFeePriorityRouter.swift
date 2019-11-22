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

        interactor.delegate = presenter
        presenter.view = view

        return (view, presenter, router)
    }

}

extension SendFeePriorityRouter: ISendFeePriorityRouter {

    func openPriorities(items: [PriorityItem], onSelect: @escaping (PriorityItem) -> ()) {
        let alertController = AlertViewController(
                header: "send.tx_speed".localized,
                rows: items.map { item in
                    AlertRow(text: "\(item.priority.title) (< \(item.duration.approximateHoursOrMinutes))", selected: item.selected)
                }
        ) { selectedIndex in
            onSelect(items[selectedIndex])
        }

        viewController?.present(alertController, animated: true)
    }

}

extension SendFeePriorityRouter: ISendSubRouter {
}
