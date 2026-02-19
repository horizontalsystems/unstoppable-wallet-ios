import Foundation

class BackupFilenameValidator {
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let destination: BackupModule.Destination

    init(destination: BackupModule.Destination) {
        self.destination = destination
    }

    func validate(name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            throw ValidationError.empty
        }

        if destination == .cloud {
            let exists = cloudBackupManager.existFilenames.contains {
                $0.lowercased() == trimmed.lowercased()
            }
            if exists {
                throw ValidationError.alreadyExists
            }
        }
    }
}

extension BackupFilenameValidator {
    enum ValidationError: LocalizedError {
        case empty
        case alreadyExists

        var errorDescription: String? {
            switch self {
            case .empty:
                return "backup.cloud.name.error.empty".localized
            case .alreadyExists:
                return "backup.cloud.name.error.already_exist".localized
            }
        }
    }
}
