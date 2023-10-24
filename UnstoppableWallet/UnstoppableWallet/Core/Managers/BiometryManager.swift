import Combine
import HsExtensions
import LocalAuthentication

class BiometryManager {
    private let biometricOnKey = "biometric_on_key"

    private let userDefaultsStorage: UserDefaultsStorage
    private var tasks = Set<AnyTask>()

    @PostPublished var biometryType: BiometryType?
    @PostPublished var biometryEnabled: Bool {
        didSet {
            userDefaultsStorage.set(value: biometryEnabled, for: biometricOnKey)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        biometryEnabled = userDefaultsStorage.value(for: biometricOnKey) ?? false

        refreshBiometry()
    }

    private func refreshBiometry() {
        Task { [weak self] in
            var authError: NSError?
            let localAuthenticationContext = LAContext()

            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                switch localAuthenticationContext.biometryType {
                case .faceID: self?.biometryType = .faceId
                case .touchID: self?.biometryType = .touchId
                default: self?.biometryType = .none
                }
            } else {
                self?.biometryType = .none
            }
        }.store(in: &tasks)
    }
}
