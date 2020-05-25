import UIKit

class SendMemoRouter {

    static func module() -> (UIView, ISendMemoModule) {
        let presenter = SendMemoPresenter(maxSymbols: 120)
        let view = SendMemoView(delegate: presenter)

        presenter.view = view

        return (view, presenter)
    }

}
