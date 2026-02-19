import Foundation
import SwiftUI

enum BackupModule {
    enum BackupType {
        case wallet(String) // single account id
        case app(Set<String>) // selected account ids + settings
    }

    enum Destination {
        case cloud
        case files
    }

    enum Step: Hashable {
        case selectDestination // choose cloud/files (shown when destination is nil)
        case selectContent // choose accounts and settings (app only)
        case disclaimer // warning with terms checkboxes
        case name // enter backup name
        case password // enter password and confirm
    }

    enum BackupResult {
        case saved // cloud: show .savedToCloud
        case share(URL) // files: show share sheet
    }

    enum BackupError: Error {
        case accountNotFound
    }

    // backups data
    struct AccountItem: Identifiable {
        let accountId: String
        let name: String
        let description: String
        let cautionType: CautionType?

        var id: String { accountId }
    }

    struct ContentItem: Identifiable {
        let title: String
        var value: String?
        var description: String?

        var id: String { title }
    }

    enum Source {
        case wallet(WalletBackup)
        case full(FullBackup)

        enum Abstract {
            case wallet
            case full
        }

        var id: String {
            switch self {
            case let .wallet(backup): return backup.id
            case let .full(backup): return backup.id
            }
        }

        var timestamp: TimeInterval? {
            switch self {
            case let .wallet(backup): return backup.timestamp
            case let .full(backup): return backup.timestamp
            }
        }
    }

    struct NamedSource {
        let name: String
        let source: Source
    }
}

extension BackupModule {
    static func backupWallet(accountId: String, destination: Destination, isPresented: Binding<Bool>) -> some View {
        BackupView(
            type: .wallet(accountId),
            destination: destination,
            isPresented: isPresented
        )
    }

    static func backupApp(isPresented: Binding<Bool>) -> some View {
        let accountManager = Core.shared.accountManager
        let accountIds = Set(accountManager.accounts.filter { !$0.watchAccount }.map(\.id))

        return BackupView(
            type: .app(accountIds),
            destination: nil,
            isPresented: isPresented
        )
    }
}

extension BackupModule {
    static let minimumPassphraseLength = 8

    enum PassphraseCharacterSet: CaseIterable {
        case lowerCased
        case upperCased
        case digits
        case customSymbols

        var set: CharacterSet {
            switch self {
            case .upperCased: return CharacterSet.uppercaseLetters
            case .lowerCased: return CharacterSet.lowercaseLetters
            case .digits: return CharacterSet.decimalDigits
            case .customSymbols: return CharacterSet(charactersIn: " '\"`&/?!:;.,~*$=+-[](){}<>\\_#@|%")
            }
        }

        func contains(_ string: String) -> Bool {
            string.rangeOfCharacter(from: set) != nil
        }
    }
}
