import Foundation
import RxSwift
import EthereumKit
import FeeRateKit
import Erc20Kit

class SendEthereumHandler {
    private var gasDisposeBag = DisposeBag()
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendEthereumInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let feePriorityModule: ISendFeePriorityModule
    private let feeModule: ISendFeeModule

    private var estimateGasLimitState: FeeState = .zero

    init(interactor: ISendEthereumInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, feeModule: ISendFeeModule, feePriorityModule: ISendFeePriorityModule) {
        self.interactor = interactor
        self.amountModule = amountModule
        self.addressModule = addressModule
        self.feeModule = feeModule
        self.feePriorityModule = feePriorityModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            try addressModule.validateAddress()

            delegate?.onChange(isValid: feeModule.isValid && feePriorityModule.feeRateState.isValid && estimateGasLimitState.isValid)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

    private func processFee(error: Error) {
        feeModule.set(externalError: error is EthereumKit.ValidationError ? nil : error)
    }

    private func syncState() {
        let loading = feePriorityModule.feeRateState.isLoading || estimateGasLimitState.isLoading

        amountModule.set(loading: loading)
        feeModule.set(loading: loading)

        guard !loading else {
            return
        }

        if case let .error(error) = feePriorityModule.feeRateState {
            feeModule.set(fee: 0)

            processFee(error: error)
        } else if case let .error(error) = estimateGasLimitState {
            feeModule.set(fee: 0)

            processFee(error: error)
        } else if case let .value(feeRateValue) = feePriorityModule.feeRateState, case let .value(estimateGasLimitValue) = estimateGasLimitState {
            amountModule.set(availableBalance: interactor.availableBalance(gasPrice: feeRateValue, gasLimit: estimateGasLimitValue))

            feeModule.set(externalError: nil)
            feeModule.set(fee: interactor.fee(gasPrice: feeRateValue, gasLimit: estimateGasLimitValue))
        }
    }

    private func syncEstimateGasLimit() {
        guard let address = try? addressModule.validAddress(), !amountModule.currentAmount.isZero else {
            onReceive(gasLimit: 0)
            return
        }
        gasDisposeBag = DisposeBag()

        estimateGasLimitState = .loading
        syncState()
        syncValidation()

        interactor.estimateGasLimit(to: address, value: amountModule.currentAmount, gasPrice: feePriorityModule.feeRate)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: onReceive, onError: onGasLimitError)
                .disposed(by: gasDisposeBag)
    }

}

extension SendEthereumHandler: ISendHandler {

    func onViewDidLoad() {
        feePriorityModule.fetchFeeRate()

        amountModule.set(minimumRequiredBalance: interactor.minimumRequiredBalance)
        if let minimumSpendableAmount = interactor.minimumSpendableAmount {
            amountModule.set(minimumAmount: minimumSpendableAmount)
        }

        feeModule.set(availableFeeBalance: interactor.ethereumBalance)
        syncState()

        syncEstimateGasLimit()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress()),
            SendConfirmationFeeViewItem(primaryInfo: feeModule.primaryAmountInfo, secondaryInfo: feeModule.secondaryAmountInfo),
            SendConfirmationDurationViewItem(timeInterval: feePriorityModule.duration)
        ]
    }

    func sync() {
        if feePriorityModule.feeRateState.isError || estimateGasLimitState.isError {
            feePriorityModule.fetchFeeRate()
            syncEstimateGasLimit()
        }
    }

    func sync(rateValue: Decimal?) {
        amountModule.set(rateValue: rateValue)
        feeModule.set(rateValue: rateValue)
    }

    func sync(inputType: SendInputType) {
        amountModule.set(inputType: inputType)
        feeModule.update(inputType: inputType)
    }

    func sendSingle() throws -> Single<Void> {
        guard let feeRate = feePriorityModule.feeRate, case let .value(gasLimit) = estimateGasLimitState else {
            throw SendTransactionError.noFee
        }
        return interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), gasPrice: feeRate, gasLimit: gasLimit)
    }

}

extension SendEthereumHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
        syncEstimateGasLimit()
    }

    func onChange(inputType: SendInputType) {
        feeModule.update(inputType: inputType)
    }

}

extension SendEthereumHandler: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncValidation()
        syncEstimateGasLimit()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}

extension SendEthereumHandler: ISendFeePriorityDelegate {

    func onUpdateFeePriority() {
        syncState()
        syncValidation()
        syncEstimateGasLimit()
    }

}

extension SendEthereumHandler {

    func onReceive(gasLimit: Int) {
        estimateGasLimitState = .value(gasLimit)

        syncState()
        syncValidation()
    }

    func onGasLimitError(_ error: Error) {
        estimateGasLimitState = .error(error.convertedError)

        syncState()
        syncValidation()
    }

}
