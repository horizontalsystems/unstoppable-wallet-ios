import Foundation
import RxSwift
import HsToolKit
import MarketKit

class SendPresenter {
    weak var view: ISendView?

    private let platformCoin: PlatformCoin

    private let handler: ISendHandler
    private let interactor: ISendInteractor
    private let router: ISendRouter
    private let logger: Logger

    init(platformCoin: PlatformCoin, handler: ISendHandler, interactor: ISendInteractor, router: ISendRouter, logger: Logger) {
        self.platformCoin = platformCoin

        self.handler = handler
        self.interactor = interactor
        self.router = router
        self.logger = logger
    }

    private func isEmptyAmountError(error: Error) -> Bool {
        if case SendAmountPresenter.ValidationError.emptyValue = error {
            return true
        } else {
            return false
        }
    }

    private func isEmptyAddressError(error: Error) -> Bool {
        if case SendAddressPresenter.ValidationError.emptyValue = error {
            return true
        } else {
            return false
        }
    }

}

extension SendPresenter: ISendViewDelegate {

    func onViewDidLoad() {
        view?.set(coin: platformCoin.coin, coinType: platformCoin.coinType)
        handler.onViewDidLoad()

        if !platformCoin.coin.isCustom {
            interactor.subscribeToCoinPrice(coinUid: platformCoin.coin.uid, currencyCode: interactor.baseCurrency.code)
        }

        let rateValue = interactor.nonExpiredRateValue(coinUid: platformCoin.coin.uid, currencyCode: interactor.baseCurrency.code)
        handler.sync(rateValue: rateValue)

        var inputType: SendInputType
        if rateValue == nil {
            inputType = .coin
        } else {
            inputType = interactor.defaultInputType
        }

        handler.sync(inputType: inputType)
    }

    func showKeyboard() {
        handler.showKeyboard()
    }

    func onClose() {
        view?.dismissKeyboard()
        router.dismiss()
    }

    func onProceedClicked() {
        do {
            router.showConfirmation(viewItems: try handler.confirmationViewItems(), delegate: self)
        } catch {
            view?.show(error: error)
        }
    }

}

extension SendPresenter: ISendHandlerDelegate {

    func onChange(isValid: Bool, amountError: Error?, addressError: Error?) {
        let actionState: ActionState

        if isValid {
            actionState = .enabled
        } else if let error = amountError, !isEmptyAmountError(error: error) {
            actionState = .disabled(error: "Invalid Amount")
        } else if let error = addressError, !isEmptyAddressError(error: error) {
            actionState = .disabled(error: "Invalid Address")
        } else {
            actionState = .disabled(error: nil)
        }

        view?.set(actionState: actionState)
    }

}

extension SendPresenter: ISendInteractorDelegate {

    func sync() {
        handler.sync()
    }

    func didSend() {
        view?.dismissWithSuccess()
    }

    func didFailToSend(error: Error) {
        view?.show(error: error.convertedError)
    }

    func didReceive(coinPrice: CoinPrice) {
        if !coinPrice.expired {
            handler.sync(rateValue: coinPrice.value)
            return
        }
        handler.sync(rateValue: nil)
    }

}

extension SendPresenter: ISendConfirmationDelegate {

    func onSendClicked() {
        let actionLogger = logger.scoped(with: "\(Int.random(in: 0..<1_000_000))")
        actionLogger.debug("Confirm clicked", save: true)

        view?.showProgress()

        do {
            interactor.send(single: try handler.sendSingle(logger: actionLogger), logger: actionLogger)
        } catch {
            actionLogger.warning("Not sending due to \(String(reflecting: error))", save: true)
            view?.show(error: error)
        }
    }

    func onCancelClicked() {
        router.dismiss()
    }

}

extension SendPresenter {

    enum ActionState {
        case enabled
        case disabled(error: String?)
    }

}
