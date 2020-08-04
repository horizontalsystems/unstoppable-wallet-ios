class ChartNotificationViewModelFactory: IChartNotificationViewModelFactory {

    func titleViewModel(coin: Coin) -> PriceAlertTitleViewModel {
        PriceAlertTitleViewModel(title: "chart_alert.title", subtitle: coin.title)
    }

    func sections(alert: PriceAlert, priceChangeUpdate: @escaping (Int) -> (), trendUpdate: @escaping (Int) -> ()) -> [PriceAlertSectionViewModel] {
        [
            PriceAlertSectionViewModel(header: "chart_alert.24h_description", rows: PriceAlert.ChangeState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.changeState == $0, action: priceChangeUpdate)
            }),
            PriceAlertSectionViewModel(header: "chart_alert.trend_description", rows: PriceAlert.TrendState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.trendState == $0, action: trendUpdate)
            })
        ]
    }

}
