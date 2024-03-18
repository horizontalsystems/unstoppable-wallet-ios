import Foundation
import MarketKit
import RxSwift

class RecipientRowsViewModel: ObservableObject {
    let disposeBag = DisposeBag()
    let evmLabelManager = App.shared.evmLabelManager
    let manager = App.shared.contactManager

    let address: String
    let blockchainType: BlockchainType

    @Published var name: String?

    init(address: String, blockchainType: BlockchainType) {
        self.address = address
        self.blockchainType = blockchainType

        subscribe(disposeBag, App.shared.contactManager.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        if let evmLabel = evmLabelManager.addressLabel(address: address) {
            name = evmLabel
            return
        }
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
    func onFetch(address: String) {}
}