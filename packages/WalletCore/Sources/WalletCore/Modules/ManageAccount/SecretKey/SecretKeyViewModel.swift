import Combine

class SecretKeyViewModel: ObservableObject {
    let kind: SecretKeyKind
    let key: String

    @Published private(set) var hidden = true

    init(kind: SecretKeyKind, accountType: AccountType) {
        self.kind = kind
        key = kind.key(accountType: accountType) ?? ""
    }

    func toggleHidden() {
        hidden.toggle()
        stat(page: kind.statPage, event: .toggleHidden)
    }

    func copy() {
        let kind = kind

        Coordinator.shared.presentCopyConfirmation(value: key) {
            stat(page: kind.statPage, event: .copy(entity: kind.statEntity))
        }
    }
}
