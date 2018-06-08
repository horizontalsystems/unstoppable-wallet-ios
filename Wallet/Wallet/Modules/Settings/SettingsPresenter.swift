import Foundation

class SettingsPresenter {

    private let router: SettingsRouterProtocol

    init(router: SettingsRouterProtocol) {
        self.router = router
    }

}

extension SettingsPresenter: SettingsViewDelegate {

}
