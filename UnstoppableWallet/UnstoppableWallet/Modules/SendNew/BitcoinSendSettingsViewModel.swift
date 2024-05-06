import Combine

class BitcoinSendSettingsViewModel: ObservableObject {
    private let handler: BitcoinPreSendHandler

    @Published var rbfEnabled: Bool

    @Published var resetEnabled = false
    @Published var doneEnabled = true

    init(handler: BitcoinPreSendHandler) {
        self.handler = handler

        rbfEnabled = handler.rbfEnabled
    }
}

extension BitcoinSendSettingsViewModel {
    func reset() {}

    func applySettings() {
        handler.rbfEnabled = rbfEnabled
    }
}
