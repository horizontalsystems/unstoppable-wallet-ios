import MarketKit

class PrivacyViewItemFactory {

    func syncViewItems(items: [PrivacySyncItem]) -> [PrivacyViewItem] {
        items.map { item in
            PrivacyViewItem(iconName: iconName(for: item.platformCoin), title: item.platformCoin.coin.name, value: item.setting.syncMode.title, changeable: item.changeable)
        }
    }

    private func iconName(for coin: PlatformCoin) -> String {
        switch coin.coinType {
        case .bitcoin: return "bitcoin_24"
        case .bitcoinCash: return "bitcoin_cash_24"
        case .litecoin: return "litecoin_24"
        case .dash: return "dash_24"
        default: return ""
        }
    }

}
