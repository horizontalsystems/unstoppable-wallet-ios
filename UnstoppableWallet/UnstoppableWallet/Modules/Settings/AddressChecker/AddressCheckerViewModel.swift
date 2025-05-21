import Combine

class AddressCheckerViewModel: ObservableObject {
    private let appSettingManager = App.shared.appSettingManager

    @Published var recipientAddressCheck: Bool {
        didSet {
            guard appSettingManager.recipientAddressCheck != recipientAddressCheck else {
                return
            }
            stat(page: .addressChecker, event: .recipientCheck(enabled: recipientAddressCheck))
            appSettingManager.recipientAddressCheck = recipientAddressCheck
        }
    }

    init() {
        recipientAddressCheck = appSettingManager.recipientAddressCheck
    }
}
