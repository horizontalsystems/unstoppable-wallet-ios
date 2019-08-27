import Foundation
import RxSwift

class SendEosHandler {
    weak var delegate: ISendHandlerDelegate?

    private let interactor: ISendEosInteractor

    private let amountModule: ISendAmountModule
    private let accountModule: ISendAccountModule
    private let memoModule: ISendMemoModule

    init(interactor: ISendEosInteractor, amountModule: ISendAmountModule, accountModule: ISendAccountModule, memoModule: ISendMemoModule) {
        self.interactor = interactor

        self.amountModule = amountModule
        self.accountModule = accountModule
        self.memoModule = memoModule
    }

    private func syncValidation() {
        do {
            _ = try amountModule.validAmount()
            _ = try accountModule.validAccount()

            delegate?.onChange(isValid: true)
        } catch {
            delegate?.onChange(isValid: false)
        }
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
            SendConfirmationAmountViewItem(primaryInfo: try amountModule.primaryAmountInfo(), secondaryInfo: try amountModule.secondaryAmountInfo(), receiver: try accountModule.validAccount())
        ]

        if let memo = memoModule.memo {
            viewItems.append(SendConfirmationMemoViewItem(memo: memo))
        }

        return viewItems
    }

    func sendSingle() throws -> Single<Void> {
        return interactor.sendSingle(amount: try amountModule.validAmount(), account: try accountModule.validAccount(), memo: memoModule.memo)
    }

}

extension SendEosHandler: ISendAmountDelegate {

    func onChangeAmount() {
        syncValidation()
    }

    func onChange(inputType: SendInputType) {
    }

}

extension SendEosHandler: ISendAccountDelegate {

    func validate(account: String) throws {
        try interactor.validate(account: account)
    }

    func onUpdateAccount() {
        syncValidation()
    }

}
