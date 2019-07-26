import Foundation

class SendFeePresenter {
    private let interactor: ISendFeeInteractor
    private let coinCode: CoinCode

    weak var view: ISendFeeView?
    weak var presenterDelegate: ISendFeePresenterDelegate?

    var feeRatePriority: FeeRatePriority = .medium

    init(interactor: ISendFeeInteractor, coinCode: CoinCode) {
        self.interactor = interactor
        self.coinCode = coinCode
    }

    private func updateFee() {
        if let fee = presenterDelegate?.fee {
            view?.set(fee: "Fee: \(fee)")
        }
    }

}

extension SendFeePresenter {

    func viewDidLoad() {
        updateFee()
    }

}

extension SendFeePresenter: ISendFeeViewDelegate {

    func onFeePriorityChange(value: Int) {

    }

}
