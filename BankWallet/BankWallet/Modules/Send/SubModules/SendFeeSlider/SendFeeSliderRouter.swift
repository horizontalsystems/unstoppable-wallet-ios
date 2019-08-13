import UIKit

class SendFeeSliderRouter {

    static func module(feeRateProvider: IFeeRateProvider) -> (UIView, ISendFeeSliderModule) {
        let interactor = SendFeeSliderInteractor(provider: feeRateProvider)
        let presenter = SendFeeSliderPresenter(interactor: interactor)
        let view = SendFeeSliderView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}
