import SwiftUI
import UIKit

struct RestoreTypeView: View {
    @StateObject private var viewModel = RestoreTypeViewModel()
    @Binding var isPresented: Bool
    var parentPresented: Binding<Bool>?
    var showClose: Bool = false

    @State private var recoveryPhrasePresented = false
    @State private var privateKeyPresented = false
    @State private var backupPresented = false

    @State private var passkeyLogin: RestoreTypeViewModel.PasskeyLogin?
    @State private var restoreSelectPresented = false

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ForEach(RestoreType.allCases) {
                    row(restoreType: $0)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("restore.title".localized)
        .navigationDestination(isPresented: $recoveryPhrasePresented) {
            RestoreMnemonicView(isParentPresented: parentPresented ?? $isPresented)
        }
        .navigationDestination(isPresented: $privateKeyPresented) {
            RestorePrivateKeyView(isParentPresented: parentPresented ?? $isPresented)
        }
        .navigationDestination(isPresented: $backupPresented) {
            RestoreBackupListView(isParentPresented: parentPresented ?? $isPresented)
        }
        .navigationDestination(isPresented: $restoreSelectPresented) {
            if let passkeyLogin {
                RestoreCoinsView(
                    accountName: passkeyLogin.accountName,
                    accountType: passkeyLogin.accountType,
                    isParentPresented: parentPresented ?? $isPresented
                )
            }
        }
        .toolbar {
            if showClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }

    @ViewBuilder private func row(restoreType: RestoreType) -> some View {
        Cell(
            left: {
                ThemeImage(restoreType.icon, size: 24)
            },
            middle: {
                MultiText(title: restoreType.title, subtitle: restoreType.description)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                handleSelect(restoreType: restoreType)
            }
        )
    }

    private func handleSelect(restoreType: RestoreType) {
        switch restoreType {
        case .recoveryPhrase:
            recoveryPhrasePresented = true
            stat(page: .importWallet, event: .open(page: .importWalletFromKey))
        case .privateKey:
            privateKeyPresented = true
            stat(page: .importWallet, event: .open(page: .importWalletFromKey))
        case .passkey:
            Task {
                do {
                    let login = try await viewModel.loginPasskey()

                    DispatchQueue.main.async {
                        passkeyLogin = login
                        restoreSelectPresented = true
                    }
                } catch {
                    if case PasskeyManager.PasskeyError.userCanceled = error {
                        return
                    }
                    DispatchQueue.main.async {
                        HudHelper.instance.show(banner: .error(string: error.smartDescription))
                    }
                }
            }
        case .backup:
            backupPresented = true
        }
    }
}

extension RestoreTypeView {
    private enum RestoreType: String, Identifiable, CaseIterable {
        case recoveryPhrase
        case privateKey
        case passkey
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
            case .privateKey: return "key_24"
            case .passkey: return "face_id"
            case .backup: return "cloud"
            }
        }
    }
}
