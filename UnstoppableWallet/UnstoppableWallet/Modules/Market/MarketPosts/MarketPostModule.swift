struct MarketPostModule {

    static func viewController() -> MarketPostViewController {
        let service = MarketPostService(postManager: App.shared.rateManager)

        let viewModel = MarketPostViewModel(service: service)
        return MarketPostViewController(postViewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
