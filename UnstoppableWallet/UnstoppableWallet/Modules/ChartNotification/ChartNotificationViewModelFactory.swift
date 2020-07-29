class ChartNotificationViewModelFactory {

    func titleViewModel(coin: Coin) -> PriceAlertTitleViewModel {
        PriceAlertTitleViewModel(title: "chart_alert.title", subtitle: coin.title)
    }

    func sections(alert: PriceAlert) -> [PriceAlertSectionViewModel] {
        [
            PriceAlertSectionViewModel(header: "chart_alert.24h_description", rows: PriceAlert.ChangeState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.changeState == $0)
            }),
            PriceAlertSectionViewModel(header: "chart_alert.trend_description", rows: PriceAlert.TrendState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.trendState == $0)
            })
        ]
    }

}
