enum RestoreSettingsModule {
    static func module(statPage: StatPage) -> (RestoreSettingsService, RestoreSettingsView) {
        let service = RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        let viewModel = RestoreSettingsViewModel(service: service)
        let view = RestoreSettingsView(viewModel: viewModel, statPage: statPage)

        return (service, view)
    }
}
