class PriceTrendAlertSettingViewModelFactory: IChartNotificationViewModelFactory {

    func titleViewModel(coin: Coin) -> PriceAlertTitleViewModel {
        PriceAlertTitleViewModel(title: "settings_notifications.trend_settings_title", subtitle: coin.title)
    }

    func sections(alert: PriceAlert, priceChangeUpdate: @escaping (Int) -> (), trendUpdate: @escaping (Int) -> ()) -> [PriceAlertSectionViewModel] {
        [
            PriceAlertSectionViewModel(header: nil, rows: PriceAlert.TrendState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.trendState == $0, action: trendUpdate)
            })
        ]
    }

}
