import UIKit

class SendFeeSliderRouter {

    static func module(coin: Coin) -> (UIView, ISendFeeSliderModule)? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin) else {
            return nil
        }

        let interactor = SendFeeSliderInteractor(provider: feeRateProvider)
        let presenter = SendFeeSliderPresenter(interactor: interactor)
        let view = SendFeeSliderView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}
