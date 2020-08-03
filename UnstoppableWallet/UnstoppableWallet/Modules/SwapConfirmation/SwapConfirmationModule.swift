import UniswapKit

protocol ISwapConfirmationDelegate: class {
    func onSwapClicked()
    func onCancelClicked()
}

protocol ISwapConfirmationView: class {
    func set(viewItem: SwapConfirmationModule.ViewItem)
}

protocol ISwapConfirmationViewDelegate {
    func onViewDidLoad()

    func onSwapClicked()
    func onCancelClicked()
}

protocol ISwapConfirmationViewItemFactory {
    func viewItem(coinIn: Coin, coinOut: Coin, tradeData: TradeData) -> SwapConfirmationModule.ViewItem
}

class SwapConfirmationModule {

    struct AdditionalDataItem {
        let title: String
        let value: String?
        let color: UIColor?
    }

    struct ViewItem {
        let payTitle: String
        let payValue: String?
        let getTitle: String
        let getValue: String?
        let additionalDataItems: [AdditionalDataItem]
    }

}
