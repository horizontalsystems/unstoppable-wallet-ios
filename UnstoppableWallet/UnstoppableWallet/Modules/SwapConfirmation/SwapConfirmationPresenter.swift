import UniswapKit

class SwapConfirmationPresenter {
    private let factory: ISwapConfirmationViewItemFactory

    weak var delegate: ISwapConfirmationDelegate?
    weak var view: ISwapConfirmationView?

    private let coinIn: Coin
    private let coinOut: Coin
    private let tradeData: TradeData

    init(factory: ISwapConfirmationViewItemFactory, coinIn: Coin, coinOut: Coin, tradeData: TradeData) {
        self.factory = factory

        self.coinIn = coinIn
        self.coinOut = coinOut
        self.tradeData = tradeData
    }

}

extension SwapConfirmationPresenter: ISwapConfirmationViewDelegate {

    func onViewDidLoad() {
        view?.set(viewItem: factory.viewItem(coinIn: coinIn, coinOut: coinOut, tradeData: tradeData))
    }

    func onSwapClicked() {
        delegate?.onSwap()
    }

    func onCancelClicked() {
        delegate?.onCancel()
    }

}
