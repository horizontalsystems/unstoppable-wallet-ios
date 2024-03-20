import Foundation
import MarketKit
import RxSwift

class RecipientRowsViewModel: ObservableObject {
    let disposeBag = DisposeBag()
    let evmLabelManager = App.shared.evmLabelManager
    let manager = App.shared.contactManager

    let address: String
    let label: String?
    let blockchainType: BlockchainType

    @Published var name: String?

    init(address: String, blockchainType: BlockchainType) {
        self.address = address
        self.blockchainType = blockchainType
        label = evmLabelManager.addressLabel(address: address)

        subscribe(disposeBag, App.shared.contactManager.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        name = manager.all?.by(address: address, blockchainUid: blockchainType.uid)?.name
    }

    var emptyContacts: Bool {
        manager.all?.isEmpty ?? true
    }
}

extension RecipientRowsViewModel {
    enum AddAddressType: String, Identifiable {
        case create, add

        var id: String { rawValue }
    }
}

extension RecipientRowsViewModel: ContactBookSelectorDelegate {
    func onFetch(address _: String) {}
}
