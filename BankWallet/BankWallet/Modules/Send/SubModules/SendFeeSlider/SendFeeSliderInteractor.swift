class SendFeeSliderInteractor {
    private let provider: IFeeRateProvider

    init(provider: IFeeRateProvider) {
        self.provider = provider
    }

}

extension SendFeeSliderInteractor: ISendFeeSliderInteractor {

    func feeRate(priority: FeeRatePriority) -> Int {
        return provider.feeRate(for: priority)
    }

}
