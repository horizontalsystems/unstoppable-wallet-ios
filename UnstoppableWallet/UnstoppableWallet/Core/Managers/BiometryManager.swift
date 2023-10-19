import Combine
import HsExtensions
import LocalAuthentication
import StorageKit

class BiometryManager {
    private let biometricOnKey = "biometric_on_key"

    private let localStorage: ILocalStorage
    private var tasks = Set<AnyTask>()

    @PostPublished var biometryType: BiometryType?
    @PostPublished var biometryEnabled: Bool {
        didSet {
            localStorage.set(value: biometryEnabled, for: biometricOnKey)
        }
    }

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage

        biometryEnabled = localStorage.value(for: biometricOnKey) ?? false

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
