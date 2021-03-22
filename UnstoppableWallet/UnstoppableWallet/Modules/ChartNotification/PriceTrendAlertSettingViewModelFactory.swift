import CoinKit

class PriceTrendAlertSettingViewModelFactory: IChartNotificationViewModelFactory {

    func titleViewModel(coinTitle: String) -> PriceAlertTitleViewModel {
        PriceAlertTitleViewModel(title: "settings_notifications.trend_settings_title", subtitle: coinTitle)
    }

    func sections(alert: PriceAlert, priceChangeUpdate: @escaping (Int) -> (), trendUpdate: @escaping (Int) -> ()) -> [PriceAlertSectionViewModel] {
        [
            PriceAlertSectionViewModel(header: nil, rows: PriceAlert.TrendState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.trendState == $0, action: trendUpdate)
            })
        ]
    }

}
