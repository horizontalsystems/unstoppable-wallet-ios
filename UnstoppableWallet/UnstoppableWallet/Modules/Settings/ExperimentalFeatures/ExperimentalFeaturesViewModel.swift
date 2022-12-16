class ExperimentalFeaturesViewModel {
    private let service: ExperimentalFeaturesService

    init(service: ExperimentalFeaturesService) {
        self.service = service
    }

}

extension ExperimentalFeaturesViewModel {

    var testNetEnabled: Bool {
        service.testNetEnabled
    }

    func onToggleTestNet(enabled: Bool) {
        service.toggleTestNet(enabled: enabled)
    }

}
