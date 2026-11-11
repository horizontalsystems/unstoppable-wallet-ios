import Foundation

enum RestoreType: String, Identifiable, CaseIterable {
    case passkey
    case recoveryPhrase
    case privateKey
    case backup

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .recoveryPhrase: return "restore_type.recovery.title".localized
        case .privateKey: return "restore_type.private_key.title".localized
        case .passkey: return "restore_type.passkey.title".localized
        case .backup: return "restore_type.backup.title".localized
        }
    }

    var description: String {
        switch self {
        case .recoveryPhrase: return "restore_type.recovery.description".localized
        case .privateKey: return "restore_type.private_key.description".localized
        case .passkey: return "restore_type.passkey.description".localized
        case .backup: return "restore_type.backup.description".localized
        }
    }

    var icon: String {
        switch self {
        case .recoveryPhrase: return "pen"
        case .privateKey: return "key"
        case .passkey: return "face_id"
        case .backup: return "cloud"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .recoveryPhrase: return TestTags.importRecoveryPhrase
        case .privateKey: return TestTags.importPrivateKey
        case .passkey: return TestTags.importPasskey
        case .backup: return TestTags.importBackupFile
        }
    }
}
