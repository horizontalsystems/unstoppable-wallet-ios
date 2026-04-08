import SwiftUI
import UIKit

struct RestoreTypeView: View {
    @StateObject private var viewModel = RestoreTypeViewModel()

    let type: BackupModule.Source.Abstract
    @Binding var isParentPresented: Bool

    @State private var showFilePicker = false
    @State private var source: BackupModule.NamedSource?
    @State private var passphrasePresented = false

    @State private var recoveryPhrasePresented = false
    @State private var cloudPresented = false
    @State private var watchPresented = false

    @State private var passkeyLogin: RestoreTypeViewModel.PasskeyLogin?
    @State private var restoreSelectPresented = false

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ForEach(restoreTypes) {
                    row(restoreType: $0)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle(title)
        .toolbar {
            if type == .full {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isParentPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $recoveryPhrasePresented) {
            RestoreViewWrapper(onRestore: { isParentPresented = false })
                .ignoresSafeArea()
                .navigationTitle("restore.title".localized)
        }
        .navigationDestination(isPresented: $cloudPresented) {
            CloudRestoreBackupListView(isParentPresented: $isParentPresented, statPage: statPage)
        }
        .navigationDestination(isPresented: $watchPresented) {
            WatchView(isParentPresented: $isParentPresented)
        }
        .navigationDestination(isPresented: $passphrasePresented) {
            if let source {
                RestorePassphraseView(
                    item: source,
                    isParentPresented: $isParentPresented,
                    statPage: statPage,
                )
            }
        }
        .navigationDestination(isPresented: $restoreSelectPresented) {
            if let passkeyLogin {
                RestoreCoinsView(
                    accountName: passkeyLogin.accountName,
                    accountType: passkeyLogin.accountType,
                    statPage: statPage,
                    onRestore: { isParentPresented = false }
                )
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result {
                do {
                    source = try RestoreFileHelper.parse(url: url, destination: .files)
                    passphrasePresented = true
                } catch {
                    HudHelper.instance.show(banner: .error(string: "alert.cant_recognize".localized))
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
        let isWallet = type == .wallet

        switch restoreType {
        case .recoveryOrPrivateKey:
            recoveryPhrasePresented = true
            stat(page: .importWallet, event: .open(page: .importWalletFromKey))
        case .cloudRestore:
            if viewModel.isCloudAvailable {
                cloudPresented = true
                stat(page: isWallet ? .importWallet : .importFull, event: .open(page: isWallet ? .importWalletFromCloud : .importFullFromCloud))
            } else {
                showCloudNotAvailable()
            }
        case .fileRestore:
            showFilePicker = true
            stat(page: isWallet ? .importWallet : .importFull, event: .open(page: isWallet ? .importWalletFromFiles : .importFullFromFiles))
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
        case .watch:
            watchPresented = true
            stat(page: isWallet ? .importWallet : .importFull, event: .open(page: .watchWallet))
        }
    }

    private func showCloudNotAvailable() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ComponentImage("icloud_24", size: .iconSize72, colorStyle: .yellow), title: "backup.cloud.no_access.title".localized),
                    .warning(text: "backup.cloud.no_access.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .yellow, title: "button.ok".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        }
    }

    private var statPage: StatPage {
        type == .wallet ? .importWalletFromFiles : .importFullFromFiles
    }

    private var title: String {
        switch type {
        case .wallet: return "restore.title".localized
        case .full: return "backup_app.restore_type.title".localized
        }
    }

    private var restoreTypes: [RestoreType] {
        switch type {
        case .wallet: return [.recoveryOrPrivateKey, .cloudRestore, .passkey, .fileRestore, .watch]
        case .full: return [.cloudRestore, .fileRestore]
        }
    }
}

extension RestoreTypeView {
    private enum RestoreType: String, Identifiable {
        case recoveryOrPrivateKey
        case cloudRestore
        case fileRestore
        case passkey
        case watch

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .recoveryOrPrivateKey: return "restore_type.recovery.title".localized
            case .cloudRestore: return "restore_type.cloud.title".localized
            case .fileRestore: return "restore_type.file.title".localized
            case .passkey: return "restore_type.passkey.title".localized
            case .watch: return "restore_type.watch.title".localized
            }
        }

        var description: String {
            switch self {
            case .recoveryOrPrivateKey: return "restore_type.recovery.description".localized
            case .cloudRestore: return "restore_type.cloud.description".localized
            case .fileRestore: return "restore_type.file.description".localized
            case .passkey: return "restore_type.passkey.description".localized
            case .watch: return "restore_type.watch.description".localized
            }
        }

        var icon: String {
            switch self {
            case .recoveryOrPrivateKey: return "pen"
            case .cloudRestore: return "cloud"
            case .fileRestore: return "file"
            case .passkey: return "face_id"
            case .watch: return "eye_on"
            }
        }
    }
}

struct FullRestoreTypeView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            RestoreTypeView(type: .full, isParentPresented: $isPresented)
        }
    }
}
