import CoinKit

class PriceChangeAlertSettingViewModelFactory: IChartNotificationViewModelFactory {

    func titleViewModel(coinTitle: String) -> PriceAlertTitleViewModel {
        PriceAlertTitleViewModel(title: "chart_alert.24h_description", subtitle: coinTitle)
    }

    func sections(alert: PriceAlert, priceChangeUpdate: @escaping (Int) -> (), trendUpdate: @escaping (Int) -> ()) -> [PriceAlertSectionViewModel] {
        [
            PriceAlertSectionViewModel(header: nil, rows: PriceAlert.ChangeState.allCases.map {
                PriceAlertSectionViewModel.Row(title: $0.description, selected: alert.changeState == $0, action: priceChangeUpdate)
            })
        ]
    }

}
