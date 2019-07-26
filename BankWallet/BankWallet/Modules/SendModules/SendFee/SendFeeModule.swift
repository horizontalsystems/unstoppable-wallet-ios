import UIKit

protocol ISendFeeView: class {
    func set(fee: String?)
    func set(convertedFee: String?)
    func set(error: String?)
}

protocol ISendFeeViewDelegate {
    func onFeePriorityChange(value: Int)
}

protocol ISendFeePresenterDelegate: class {
    var fee: Decimal { get }
}

protocol ISendFeeInteractor {
}

protocol ISendFeeInteractorDelegate: class {
}

protocol ISendFeeModule: ISendModule {
    var feeRatePriority: FeeRatePriority { get }

    func update(fee: Decimal)
}

class SendFeeModule {
    private let sendView: SendFeeView
    private let presenter: SendFeePresenter


    init(adapter: IAdapter, rateStorage: IRateStorage, delegate: ISendFeePresenterDelegate) {
        let interactor = SendFeeInteractor(rateStorage: rateStorage)

        presenter = SendFeePresenter(interactor: interactor, coinCode: adapter.feeCoinCode ?? adapter.wallet.coin.code)
        sendView = SendFeeView(feeAdjustable: true, delegate: presenter)

        presenter.view = sendView
        presenter.presenterDelegate = delegate
    }

}

extension SendFeeModule: ISendModule {

    var view: UIView {
        return sendView
    }

    var height: CGFloat {
        return SendTheme.feeHeight
    }

    func viewDidLoad() {
        presenter.viewDidLoad()
    }

}

extension SendFeeModule: ISendFeeModule {

    func update(fee: Decimal) {

    }

    var feeRatePriority: FeeRatePriority {
        return presenter.feeRatePriority
    }

}
