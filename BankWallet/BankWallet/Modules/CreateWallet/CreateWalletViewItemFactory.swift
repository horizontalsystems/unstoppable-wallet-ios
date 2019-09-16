class CreateWalletViewItemFactory {

    func viewItems(coins: [Coin], selectedIndex: Int) -> [CreateWalletViewItem] {
        return coins.enumerated().map { (index, coin) in
            CreateWalletViewItem(title: coin.title, code: coin.code, selected: index == selectedIndex)
        }
    }

}
