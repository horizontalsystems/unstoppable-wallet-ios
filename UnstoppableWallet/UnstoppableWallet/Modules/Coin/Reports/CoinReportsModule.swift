struct CoinReportsModule {

    static func viewController(coinUid: String) -> CoinReportsViewController {
        let service = CoinReportsService(coinUid: coinUid, marketKit: App.shared.marketKit)
        let viewModel = CoinReportsViewModel(service: service)
        return CoinReportsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
