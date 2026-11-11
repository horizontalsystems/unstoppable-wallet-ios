import Combine
import SwiftUI

class WelcomeViewModel: ObservableObject {
    private let termsManager = Core.shared.termsManager
    private lazy var restoreTypeViewModel = RestoreTypeViewModel()

    private var sheetPresented = false
    private var pushPending = false
    private var passkeyTask: Task<Void, Never>?

    @Published var flow: Flow?
    @Published private(set) var finishRequested = false

    func showCreateSheet() {
        showSheet(title: "intro.create_wallet.title".localized, groups: [Self.createOptions], bottomPadding: .margin32)
    }

    func showImportSheet() {
        showSheet(title: "restore.title".localized, groups: [Self.importOptions, Self.watchOptions], bottomPadding: .margin32)
    }

    func handleFlowFinished() {
        guard !finishRequested else {
            return
        }

        finishRequested = true
    }

    private var isIdle: Bool {
        !pushPending && flow == nil && !finishRequested && passkeyTask == nil
    }

    private func showSheet(title: String, groups: [[Option]], bottomPadding: CGFloat) {
        guard !sheetPresented, isIdle else {
            return
        }

        sheetPresented = true

        Coordinator.shared.present(type: .bottomSheet) { [weak self] isPresented in
            WelcomeWalletSheetView(title: title, groups: groups, bottomPadding: bottomPadding, isPresented: isPresented) { option in
                self?.select(option, isPresented: isPresented)
            }
        } onDismiss: { [weak self] in
            self?.sheetPresented = false
        }
    }

    private func select(_ option: Option, isPresented: Binding<Bool>) {
        guard sheetPresented, isIdle else {
            return
        }

        sheetPresented = false
        isPresented.wrappedValue = false

        switch option {
        case .createStandard:
            push(.createStandard)
        case .createPasskey:
            push(termsManager.passkeyTermsAccepted ? .createPasskey : .passkeyTerms)
        case .restore(.recoveryPhrase):
            push(.restoreMnemonic)
            stat(page: .importWallet, event: .open(page: .importWalletFromKey))
        case .restore(.privateKey):
            push(.restorePrivateKey)
            stat(page: .importWallet, event: .open(page: .importWalletFromKey))
        case .restore(.backup):
            push(.restoreBackup)
        case .restore(.passkey):
            loginPasskey()
        case .watch:
            push(.watch)
            stat(page: .addWallet, event: .open(page: .watchWallet))
        }
    }

    private func loginPasskey() {
        guard passkeyTask == nil else {
            return
        }

        passkeyTask = Task { @MainActor [weak self, restoreTypeViewModel] in
            let result: Result<RestoreTypeViewModel.PasskeyLogin, Error>

            do {
                result = try await .success(restoreTypeViewModel.loginPasskey())
            } catch {
                result = .failure(error)
            }

            guard let self else {
                return
            }

            passkeyTask = nil

            switch result {
            case let .success(login):
                push(.restoreCoins(login))
            case let .failure(error):
                if case PasskeyManager.PasskeyError.userCanceled = error {
                    return
                }

                HudHelper.instance.show(banner: .error(string: error.smartDescription))
            }
        }
    }

    /// The push waits one main-queue turn so it is not part of the transaction that dismisses the bottom sheet.
    /// `pushPending` keeps every entry point closed in the meantime.
    private func push(_ flow: Flow) {
        guard isIdle else {
            return
        }

        pushPending = true

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            pushPending = false

            guard isIdle else {
                return
            }

            self.flow = flow
        }
    }
}

extension WelcomeViewModel {
    enum Option {
        case createPasskey
        case createStandard
        case restore(RestoreType)
        case watch

        var title: String {
            switch self {
            case .createPasskey: return "new_wallet.passkey".localized
            case .createStandard: return "new_wallet.standard".localized
            case let .restore(type): return type.title
            case .watch: return "add_wallet.watch_wallet".localized
            }
        }

        var description: String {
            switch self {
            case .createPasskey: return "new_wallet.passkey.description".localized
            case .createStandard: return "new_wallet.standard.description".localized
            case let .restore(type): return type.description
            case .watch: return "add_wallet.watch_wallet.description".localized
            }
        }

        var icon: String {
            switch self {
            case .createPasskey: return "face_id"
            case .createStandard: return "list"
            case let .restore(type): return type.icon
            case .watch: return "eye_on"
            }
        }

        var accessibilityIdentifier: String {
            switch self {
            case .createPasskey: return TestTags.createTypePasskey
            case .createStandard: return TestTags.createTypeStandard
            case let .restore(type): return type.accessibilityIdentifier
            case .watch: return TestTags.onboardingWatchWallet
            }
        }
    }

    enum Flow: Hashable {
        case createStandard
        case createPasskey
        case passkeyTerms
        case restoreMnemonic
        case restorePrivateKey
        case restoreCoins(RestoreTypeViewModel.PasskeyLogin)
        case restoreBackup
        case watch
    }

    static let createOptions: [Option] = [.createPasskey, .createStandard]
    static let importOptions: [Option] = [.restore(.passkey), .restore(.recoveryPhrase), .restore(.privateKey), .restore(.backup)]
    static let watchOptions: [Option] = [.watch]
}
