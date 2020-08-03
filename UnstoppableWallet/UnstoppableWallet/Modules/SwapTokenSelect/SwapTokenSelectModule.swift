protocol ISwapTokenSelectView: class {
    func set(viewItems: [CoinBalanceViewItem])
}

protocol ISwapTokenSelectViewDelegate {
    func onLoad()
    func onSelect(coin: Coin)
    func onTapClose()
}

protocol ISwapTokenSelectInteractor {
    func coins(accountCoins: Bool, exclude: [Coin]) -> [CoinBalanceItem]
}

protocol ISwapTokenSelectInteractorDelegate: AnyObject {
}

protocol ISwapTokenSelectRouter {
    func close()
}

protocol ICoinBalanceViewItemFactory {
    func viewItem(item: CoinBalanceItem) -> CoinBalanceViewItem
}

protocol ICoinSelectDelegate {
    func didSelect(accountCoins: Bool, coin: Coin)
}

struct CoinBalanceViewItem {
    let coin: Coin
    let balance: String?
}
