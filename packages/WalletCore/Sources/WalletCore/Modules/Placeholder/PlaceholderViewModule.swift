enum PlaceholderViewModule {
    static func reachabilityView(layoutType: PlaceholderView.LayoutType = .upperMiddle) -> PlaceholderView {
        let service = ReachabilityService(reachabilityManager: Core.shared.reachabilityManager)
        let viewModel = ReachabilityViewModel(service: service)
        return PlaceholderView(layoutType: layoutType, reachabilityViewModel: viewModel)
    }
}
