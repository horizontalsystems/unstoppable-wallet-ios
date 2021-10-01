struct MarketPostModule {

    static func viewController() -> MarketPostViewController {
        let service = MarketPostService(marketKit: App.shared.marketKit)
        let viewModel = MarketPostViewModel(service: service)
        return MarketPostViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
