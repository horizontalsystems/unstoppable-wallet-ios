import Combine
import HsExtensions
import LocalAuthentication

class BiometryManager {
    private let biometricOnKey = "biometric_on_key"
    private let biometricEnabledTypeKey = "biometric_enabled_type_key"

    private let userDefaultsStorage: UserDefaultsStorage
    private var tasks = Set<AnyTask>()

    @PostPublished var biometryType: BiometryType?
    @PostPublished var biometryEnabledType: BiometryEnabledType {
        didSet {
            userDefaultsStorage.set(value: biometryEnabledType.rawValue, for: biometricEnabledTypeKey)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let earlyBiometricOn: Bool = userDefaultsStorage.value(for: biometricOnKey) {
            let biometryEnabledType: BiometryEnabledType = earlyBiometricOn ? .on : .off
            userDefaultsStorage.set(value: Bool?._createNil, for: biometricOnKey)
            userDefaultsStorage.set(value: biometryEnabledType.rawValue, for: biometricEnabledTypeKey)
        }
        let value: String? = userDefaultsStorage.value(for: biometricEnabledTypeKey)
        biometryEnabledType = value.flatMap { BiometryEnabledType(rawValue: $0) } ?? .off

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

extension BiometryManager {
    enum BiometryEnabledType: String, CaseIterable {
        case off
        case manual
        case on

        var isEnabled: Bool {
            self != .off
        }

        var isAuto: Bool {
            self == .on
        }

        var title: String {
            switch self {
            case .off: return "biometry.off".localized
            case .manual: return "biometry.manual".localized
            case .on: return "biometry.on".localized
            }
        }

        var description: String {
            switch self {
            case .off: return "biometry.off.description".localized
            case .manual: return "biometry.manual.description".localized
            case .on: return "biometry.on.description".localized
            }
        }
    }
}
