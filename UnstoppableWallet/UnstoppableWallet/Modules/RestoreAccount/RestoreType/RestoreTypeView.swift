import SwiftUI
import UIKit

struct RestoreTypeView: View {
    let type: BackupModule.Source.Abstract
    var onRestore: (() -> Void)? = nil
    @Binding var isPresented: Bool

    @StateObject private var viewModel: RestoreTypeViewModel
    @State private var path = NavigationPath()
    @State private var showFilePicker = false
    @State private var namedSource: BackupModule.NamedSource?
    @State private var selectCoinsAccount: Account?
    @State private var fileConfigRawBackup: RawFullBackup?

    private enum Route: Hashable {
        case recoveryOrPrivateKey
        case cloudRestore
        case passphrase
        case selectCoins
        case fileConfiguration
    }

    init(type: BackupModule.Source.Abstract, onRestore: (() -> Void)? = nil, isPresented: Binding<Bool>) {
        self.type = type
        self.onRestore = onRestore

        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue:
            RestoreTypeViewModel(
                cloudAccountBackupManager: Core.shared.cloudBackupManager,
                sourceType: type
            )
        )
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ScrollableThemeView {
                ForEach(viewModel.items) {
                    row(item: $0)
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .recoveryOrPrivateKey:

                    // import passphrase or private key form
                    RestoreViewWrapper(onRestore: handleRestore)
                        .ignoresSafeArea()
                        .navigationTitle("restore.title".localized)
                case .cloudRestore:

                    // show cloud list view
                    CloudRestoreBackupListView(isPresented: $isPresented, path: $path, onSelectBackup: { source in
                        namedSource = source
                        path.append(Route.passphrase)
                    })
                case .passphrase:

                    // after picked url from files or select in cloud show passphrase
                    if let source = namedSource {
                        showPassphrase(source)
                    }
                case .selectCoins:

                    // show select coins for account(after import wallet from files or cloud)
                    if let account = selectCoinsAccount {
                        RestoreSelectWrapper(account: account, statPage: passphraseStatPage, onRestore: handleRestore)
                            .ignoresSafeArea()
                            .navigationTitle("restore.title".localized)
                    }
                case .fileConfiguration:

                    // show all wallets & configurations after import fullBackup from files or cloud)
                    if let rawBackup = fileConfigRawBackup {
                        RestoreFileConfigurationView(rawBackup: rawBackup, statPage: passphraseStatPage, isPresented: $isPresented, onRestore: handleRestore)
                    }
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result {
                viewModel.didPick(url: url, destination: .files)
            }
        }
        .onReceive(viewModel.showModulePublisher) { type in
            let isWallet = viewModel.sourceType == .wallet
            switch type {
            // tap on 'import passphrase' just open import-wallet
            case .recoveryOrPrivateKey:
                stat(page: .importWallet, event: .open(page: .importWalletFromKey))
                path.append(Route.recoveryOrPrivateKey)

            // tap on iCloud: open list of iCloud backups
            case .cloudRestore:
                stat(page: isWallet ? .importWallet : .importFull, event: .open(page: isWallet ? .importWalletFromCloud : .importFullFromCloud))
                path.append(Route.cloudRestore)

            // tap on fileRestore - open standart ios file picker
            case .fileRestore:
                stat(page: isWallet ? .importWallet : .importFull, event: .open(page: isWallet ? .importWalletFromFiles : .importFullFromFiles))
                showFilePicker = true
            }
        }
        .onReceive(viewModel.showCloudNotAvailablePublisher) {
            showCloudNotAvailable()
        }
        .onReceive(viewModel.showWrongFilePublisher) {
            HudHelper.instance.show(banner: .error(string: "alert.cant_recognize".localized))
        }
        // after pick file we need open input-passphrase for json file
        .onReceive(viewModel.showRestoreBackupPublisher) { source in
            namedSource = source
            path.append(Route.passphrase)
        }
    }

    @ViewBuilder private func row(item: RestoreTypeModule.RestoreType) -> some View {
        ListSection {
            Cell(
                left: {
                    Image(viewModel.icon(type: item)).icon(size: 24)
                },
                middle: {
                    MultiText(title: viewModel.title(type: item), subtitle: viewModel.description(type: item))
                },
                action: {
                    viewModel.onTap(type: item)
                }
            )
        }
        .padding(.top, .margin4)
    }

    @ViewBuilder private func showPassphrase(_ source: BackupModule.NamedSource) -> some View {
        RestorePassphraseView(
            item: source,
            statPage: passphraseStatPage,
            isPresented: $isPresented,
            onSelectCoins: { account in
                selectCoinsAccount = account
                path.append(Route.selectCoins)
            },
            onConfiguration: { rawBackup in
                fileConfigRawBackup = rawBackup
                path.append(Route.fileConfiguration)
            },
            onRestore: handleRestore
        )
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

    private var handleRestore: () -> Void {
        if let onRestore {
            return onRestore
        }
        return { isPresented = false }
    }

    private var passphraseStatPage: StatPage {
        viewModel.sourceType == .wallet ? .importWalletFromFiles : .importFullFromFiles
    }
}

private struct RestoreViewWrapper: UIViewControllerRepresentable {
    let onRestore: () -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
        RestoreModule.viewController(onRestore: onRestore)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

private struct RestoreSelectWrapper: UIViewControllerRepresentable {
    let account: Account
    let statPage: StatPage
    let onRestore: () -> Void

    func makeUIViewController(context _: Context) -> UIViewController {
        RestoreSelectModule.viewController(
            accountName: account.name,
            accountType: account.type,
            statPage: statPage,
            isManualBackedUp: account.backedUp,
            isFileBackedUp: account.fileBackedUp,
            onRestore: onRestore
        )
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
