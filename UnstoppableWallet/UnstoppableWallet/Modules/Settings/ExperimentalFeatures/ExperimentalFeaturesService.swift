class ExperimentalFeaturesService {
    private let testNetManager: TestNetManager

    init(testNetManager: TestNetManager) {
        self.testNetManager = testNetManager
    }
}

extension ExperimentalFeaturesService {

    var testNetEnabled: Bool {
        testNetManager.testNetEnabled
    }

    func toggleTestNet(enabled: Bool) {
        testNetManager.testNetEnabled = enabled
    }

}
