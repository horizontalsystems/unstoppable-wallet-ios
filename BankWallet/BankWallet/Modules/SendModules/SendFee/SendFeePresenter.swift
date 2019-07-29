import Foundation

class SendFeePresenter {
    private let interactor: ISendFeeInteractor
    private let presenterHelper: SendAmountPresenterHelper

    private let coinCode: CoinCode
    private let currencyCode: String

    weak var view: ISendFeeView?
    weak var presenterDelegate: ISendFeePresenterDelegate?

    private var rate: Rate?
    private var sendInputType: SendInputType = .coin

    private var fee: Decimal = 0
    var feeRatePriority: FeeRatePriority = .medium

    init(interactor: ISendFeeInteractor, presenterHelper: SendAmountPresenterHelper, coinCode: CoinCode, currencyCode: String) {
        self.interactor = interactor
        self.presenterHelper = presenterHelper
        self.coinCode = coinCode
        self.currencyCode = currencyCode
    }

    private func updateFeeLabels() {
        view?.set(fee: presenterHelper.formattedWithCode(value: fee, inputType: sendInputType, rate: rate))
        view?.set(convertedFee: presenterHelper.formattedWithCode(value: fee, inputType: sendInputType.reversed, rate: rate))
    }

}

extension SendFeePresenter {

    func viewDidLoad() {
        rate = interactor.rate(coinCode: coinCode, currencyCode: currencyCode)

        updateFeeLabels()
    }

    func update(fee: Decimal) {
        self.fee = fee

        updateFeeLabels()
    }

    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal) {
        //helper
        let feeValue = CoinValue(coinCode: self.coinCode, value: fee)
        if let amount = ValueFormatter.instance.format(coinValue: feeValue) {
            view?.set(error: "send_erc.alert".localized(coinCode, amount))
        }
//
//    private func set(feeError: FeeError?) {
//        guard let error = feeError, case .erc20error(let erc20CoinCode, let fee) = error, let amount = ValueFormatter.instance.format(coinValue: fee) else {
//            feeItem.bindError?(nil)
//            return
//        }
//
//        feeItem.bindError?("send_erc.alert".localized(erc20CoinCode, amount))
//    }

    }

    func update(sendInputType: SendInputType) {
        self.sendInputType = sendInputType

        updateFeeLabels()
    }

}

extension SendFeePresenter: ISendFeeViewDelegate {

    func onFeePriorityChange(value: Int) {
        feeRatePriority = FeeRatePriority(rawValue: value) ?? .medium

        presenterDelegate?.updateFee()
    }

}
