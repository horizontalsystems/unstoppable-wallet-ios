import SwiftUI
import UIKit

struct RestoreTypeView: View {
    @StateObject private var viewModel = RestoreTypeViewModel()
    @Binding var isParentPresented: Bool

    @State private var recoveryPhrasePresented = false
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
            RestoreViewWrapper(onRestore: { isParentPresented = false })
                .ignoresSafeArea()
                .navigationTitle("restore.title".localized)
        }
        .navigationDestination(isPresented: $backupPresented) {
            RestoreBackupListView(isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $restoreSelectPresented) {
            if let passkeyLogin {
                RestoreCoinsView(
                    accountName: passkeyLogin.accountName,
                    accountType: passkeyLogin.accountType,
                    onRestore: { isParentPresented = false }
                )
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
        case .recoveryOrPrivateKey:
            recoveryPhrasePresented = true
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
                    DispatchQueue.main.async {
                        HudHelper.instance.show(banner: .error(string: error.smartDescription))
                    }
                }
            }
        case .backup:
            backupPresented = true
            // if viewModel.isCloudAvailable {
            //     stat(page: isWallet ? .importWallet : .importFull, event: .open(page: isWallet ? .importWalletFromCloud : .importFullFromCloud))
            // } else {
            //     showCloudNotAvailable()
            // }
        }
    }

    // private func showCloudNotAvailable() {
    //     Coordinator.shared.present(type: .bottomSheet) { isPresented in
    //         BottomSheetView(
    //             items: [
    //                 .title(icon: ComponentImage("icloud_24", size: .iconSize72, colorStyle: .yellow), title: "backup.cloud.no_access.title".localized),
    //                 .warning(text: "backup.cloud.no_access.description".localized),
    //                 .buttonGroup(.init(buttons: [
    //                     .init(style: .yellow, title: "button.ok".localized) {
    //                         isPresented.wrappedValue = false
    //                     },
    //                 ])),
    //             ]
    //         )
    //     }
    // }
}

extension RestoreTypeView {
    private enum RestoreType: String, Identifiable, CaseIterable {
        case recoveryOrPrivateKey
        case passkey
        case backup

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .recoveryOrPrivateKey: return "restore_type.recovery.title".localized
            case .passkey: return "restore_type.passkey.title".localized
            case .backup: return "restore_type.backup.title".localized
            }
        }

        var description: String {
            switch self {
            case .recoveryOrPrivateKey: return "restore_type.recovery.description".localized
            case .passkey: return "restore_type.passkey.description".localized
            case .backup: return "restore_type.backup.description".localized
            }
        }

        var icon: String {
            switch self {
            case .recoveryOrPrivateKey: return "pen"
            case .passkey: return "face_id"
            case .backup: return "cloud"
            }
        }
    }
}
