import Combine

final class ZcashViewingKeyViewModel: ObservableObject {
    @Published private(set) var key = ""

    init(accountType: AccountType) {
        // deriving from a seed runs the Rust key derivation, which is kept off the main thread
        Task { @MainActor [weak self] in
            let key = await Task.detached(priority: .userInitiated) {
                ZcashAdapter.unifiedFullViewingKey(accountType: accountType)
            }.value

            self?.key = key ?? ""
        }
    }

    func copy() {
        CopyHelper.copyAndNotify(value: key)
        stat(page: .zcashViewingKey, event: .copy(entity: .zcashViewingKey))
    }
}
