import Combine
import MarketKit

class RestoreSettingsView {
    private let viewModel: RestoreSettingsViewModel
    private let statPage: StatPage
    private var cancellables: [AnyCancellable] = []

    init(viewModel: RestoreSettingsViewModel, statPage: StatPage) {
        self.viewModel = viewModel
        self.statPage = statPage

        viewModel.openRequestPublisher.sink { [weak self] request in
            self?.show(request: request)
        }.store(in: &cancellables)
    }

    private func show(request: RestoreSettingsService.Request) {
        request.handler.request(token: request.token, statPage: statPage, onEnter: { [weak self] settings in
            self?.viewModel.onEnter(settings: settings)
        }, onCancel: { [weak self] in
            self?.viewModel.onCancel()
        })
    }
}
