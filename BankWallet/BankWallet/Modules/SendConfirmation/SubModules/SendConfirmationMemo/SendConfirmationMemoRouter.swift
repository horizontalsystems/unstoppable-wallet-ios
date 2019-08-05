import UIKit

class SendConfirmationMemoRouter {

    static func module() -> (UIView, ISendConfirmationMemoModule) {
        let presenter = SendConfirmationMemoPresenter(maximumSymbols: 120)
        let sendView = SendConfirmationMemoView(delegate: presenter)

        presenter.view = sendView

        return (sendView, presenter)
    }

}
