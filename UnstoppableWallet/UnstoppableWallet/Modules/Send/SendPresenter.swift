import Foundation
import RxSwift
import XRatesKit

class SendPresenter {
    weak var view: ISendView?

    private let coin: Coin

    private let handler: ISendHandler
    private let interactor: ISendInteractor
    private let router: ISendRouter

    init(coin: Coin, handler: ISendHandler, interactor: ISendInteractor, router: ISendRouter) {
        self.coin = coin

        self.handler = handler
        self.interactor = interactor
        self.router = router
    }

}

extension SendPresenter: ISendViewDelegate {

    func onViewDidLoad() {
        view?.set(coin: coin)
        handler.onViewDidLoad()

        interactor.subscribeToMarketInfo(coinCode: coin.code, currencyCode: interactor.baseCurrency.code)

        let rateValue = interactor.nonExpiredRateValue(coinCode: coin.code, currencyCode: interactor.baseCurrency.code)
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

    func onChange(isValid: Bool) {
        view?.set(sendButtonEnabled: isValid)
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

    func didReceive(marketInfo: MarketInfo) {
        if !marketInfo.expired {
            handler.sync(rateValue: marketInfo.rate)
        }
        handler.sync(rateValue: nil)
    }

}

extension SendPresenter: ISendConfirmationDelegate {

    func onSendClicked() {
        view?.showProgress()

        do {
            interactor.send(single: try handler.sendSingle())
        } catch {
            view?.show(error: error)
        }
    }

    func onCancelClicked() {
        router.dismiss()
    }

}
