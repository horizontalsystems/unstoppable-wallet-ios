import Combine

final class PublicAddressViewModel: ObservableObject {
    let kind: PublicAddressKind
    let address: String

    init(kind: PublicAddressKind, account: Account) {
        self.kind = kind
        address = kind.address(account: account) ?? ""
    }

    func copy() {
        CopyHelper.copyAndNotify(value: address)
        stat(page: kind.statPage, event: .copy(entity: kind.statEntity))
    }
}
