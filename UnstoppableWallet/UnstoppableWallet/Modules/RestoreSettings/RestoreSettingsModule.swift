struct RestoreSettingsModule {

    static func module() -> (RestoreSettingsService, RestoreSettingsView) {
        let service = RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        let viewModel = RestoreSettingsViewModel(service: service)
        let view = RestoreSettingsView(viewModel: viewModel)

        return (service, view)
    }

}
