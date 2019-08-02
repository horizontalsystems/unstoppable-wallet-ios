import Foundation

class SendFeePresenter {
    private let interactor: ISendFeeInteractor
    private let formatHelper: ISendFeeFormatHelper
    private let currencyManager: ICurrencyManager

    private let coinCode: CoinCode

    weak var view: ISendFeeView?
    weak var delegate: ISendFeeDelegate?

    private var rate: Rate?
    private var sendInputType: SendInputType = .coin

    var feeRatePriority: FeeRatePriority = .medium
    var feeRate: Int = 0
    private var fee: Decimal = 0
    private var insufficientFeeBalanceWithRequiredFee: Decimal?

    init(interactor: ISendFeeInteractor, formatHelper: ISendFeeFormatHelper, currencyManager: ICurrencyManager, coinCode: CoinCode) {
        self.interactor = interactor
        self.formatHelper = formatHelper
        self.currencyManager = currencyManager
        self.coinCode = coinCode
    }

    private func updateFeeLabels() {
        view?.set(fee: formatHelper.formattedWithCode(value: fee, inputType: sendInputType, rate: rate))
        view?.set(convertedFee: formatHelper.formattedWithCode(value: fee, inputType: sendInputType.reversed, rate: rate))
    }

}

extension SendFeePresenter: ISendFeeModule {

    var coinFee: CoinValue {
        return CoinValue(coinCode: coinCode, value: fee)
    }

    var fiatFee: CurrencyValue? {
        return formatHelper.convert(value: fee, currency: currencyManager.baseCurrency, rate: rate)
    }

    var validState: Bool {
        return insufficientFeeBalanceWithRequiredFee == nil
    }

    func update(fee: Decimal) {
        self.fee = fee

        updateFeeLabels()
    }

    func insufficientFeeBalance(coinCode: CoinCode, fee: Decimal) {
        insufficientFeeBalanceWithRequiredFee = fee
        view?.set(error: formatHelper.errorValue(fee: fee, coinCode: coinCode))
    }

    func update(sendInputType: SendInputType) {
        self.sendInputType = sendInputType

        updateFeeLabels()
    }

}

extension SendFeePresenter: ISendFeeViewDelegate {

    func viewDidLoad() {
        rate = interactor.rate(coinCode: coinCode, currencyCode: currencyManager.baseCurrency.code)
        feeRate = delegate?.feeRate(priority: feeRatePriority) ?? 0

        updateFeeLabels()
    }

    func onFeePriorityChange(value: Int) {
        feeRatePriority = FeeRatePriority(rawValue: value) ?? .medium
        feeRate = delegate?.feeRate(priority: feeRatePriority) ?? 0

        delegate?.updateFeeRate()
    }

}
