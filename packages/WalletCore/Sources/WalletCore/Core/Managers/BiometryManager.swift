import Combine
import HsExtensions
import LocalAuthentication

public class BiometryManager {
    private let biometricOnKey = "biometric_on_key"
    private let biometricEnabledTypeKey = "biometric_enabled_type_key"

    private let userDefaultsStorage: UserDefaultsStorage
    private var tasks = Set<AnyTask>()

    @PostPublished public private(set) var biometryType: BiometryType?
    @PostPublished public var biometryEnabledType: BiometryEnabledType {
        didSet {
            userDefaultsStorage.set(value: biometryEnabledType.rawValue, for: biometricEnabledTypeKey)
        }
    }

    public init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        if let earlyBiometricOn: Bool = userDefaultsStorage.value(for: biometricOnKey) {
            let biometryEnabledType: BiometryEnabledType = earlyBiometricOn ? .on : .off
            userDefaultsStorage.set(value: Bool?.none, for: biometricOnKey)
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

public extension BiometryManager {
    enum BiometryEnabledType: String, CaseIterable {
        case off
        case manual
        case on

        public var isEnabled: Bool {
            self != .off
        }

        public var isAuto: Bool {
            self == .on
        }

        public var title: LocalizedStringResource {
            switch self {
            case .off: return .package("biometry.off")
            case .manual: return .package("biometry.manual")
            case .on: return .package("biometry.on")
            }
        }
    }
}
