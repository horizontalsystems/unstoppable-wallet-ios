import Foundation
import RxSwift
import HsToolKit

class SendZCashHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendZCashInteractor

    private let amountModule: ISendAmountModule
    private let addressModule: ISendAddressModule
    private let memoModule: ISendMemoModule

    init(interactor: ISendZCashInteractor, amountModule: ISendAmountModule, addressModule: ISendAddressModule, memoModule: ISendMemoModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.addressModule = addressModule
        self.memoModule = memoModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            _ = try addressModule.validAddress()

            delegate?.onChange(isValid: true)
        } catch {
            delegate?.onChange(isValid: false)
        }
    }

    private func syncAvailableBalance() {
        amountModule.set(availableBalance: interactor.availableBalance)
    }

}

extension SendZCashHandler: ISendHandler {

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
        interactor.sendSingle(amount: try amountModule.validAmount(), address: try addressModule.validAddress(), memo: memoModule.memo)
                .do(onSubscribe: { logger.debug("Sending to ISendZCashInteractor", save: true) })
    }

}

extension SendZCashHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
    }

}

extension SendZCashHandler: ISendAddressDelegate {

    func validate(address: String) throws {
        try interactor.validate(address: address)
    }

    func onUpdateAddress() {
        syncValidation()
    }

    func onUpdate(amount: Decimal) {
        amountModule.set(amount: amount)
    }

}
