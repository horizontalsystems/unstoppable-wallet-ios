import Combine
import Foundation

class AddressCheckerViewModel: ObservableObject {
    private let appSettingManager = App.shared.appSettingManager
    private let purchaseManager = App.shared.purchaseManager
    private var cancellables = Set<AnyCancellable>()

    @Published var activated = false

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
        activated = purchaseManager.activated(.addressChecker)

        purchaseManager
            .$activeFeatures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] features in
                self?.activated = features.contains(.addressChecker)
            }
            .store(in: &cancellables)
    }
}
