import Foundation
import RxSwift
import HsToolKit

class SendEosHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendEosInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let memoModule: ISendMemoModule

    init(interactor: ISendEosInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, memoModule: ISendMemoModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.memoModule = memoModule
    }

    private func syncValidation() {
        var amountError: Error?
        var addressError: Error?

        do {
            _ = try amountModule.validAmount()
        } catch {
            amountError = error
        }

        do {
            try addressModule.validateAddress()
        } catch {
            addressError = error
        }

        delegate?.onChange(isValid: amountError == nil && addressError == nil, amountError: amountError, addressError: addressError)
    }

    private func syncAvailableBalance() {
        amountModule.set(availableBalance: interactor.availableBalance)
    }

}

extension SendEosHandler: ISendHandler {

    func onViewDidLoad() {
        syncAvailableBalance()
    }

    func showKeyboard() {
        amountModule.showKeyboard()
    }

    func confirmationViewItems() throws -> [ISendConfirmationViewItemNew] {
        var viewItems: [ISendConfirmationViewItemNew] = [
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try addressModule.validAddress())
        ]

        if let memo = memoModule.memo {
            viewItems.append(SendConfirmationMemoViewItem(memo: memo))
        }

        return viewItems
    }

    func sync() {
    }

    func sync(rateValue: Decimal?) {
        amountModule.set(rateValue: rateValue)
    }

    func sync(inputType: SendInputType) {
        amountModule.set(inputType: inputType)
    }

    func sendSingle(logger: Logger) throws -> Single<Void> {
        interactor.sendSingle(amount: try amountModule.validAmount(), account: try addressModule.validAddress().raw, memo: memoModule.memo)
                .do(onSubscribe: { logger.debug("Sending to ISendEosInteractor", save: true) })
    }

}

extension SendEosHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
    }

}

extension SendEosHandler: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(account: address)
    }

    func onUpdateAddress() {
        syncValidation()
    }

    func onUpdate(amount: Decimal) {
    }

}
