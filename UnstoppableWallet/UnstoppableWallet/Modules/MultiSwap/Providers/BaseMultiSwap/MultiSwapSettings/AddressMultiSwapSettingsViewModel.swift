import Combine
import Foundation
import MarketKit

class AddressMultiSwapSettingsViewModel: ObservableObject {
    private let storage: MultiSwapSettingStorage
    let blockchainType: BlockchainType
    private let initialAddress: Address?

    private var syncSubject = PassthroughSubject<Void, Never>()

    @Published var address: String? {
        didSet {
            syncSubject.send()
        }
    }

    init(storage: MultiSwapSettingStorage, blockchainType: BlockchainType) {
        self.storage = storage
        self.blockchainType = blockchainType

        initialAddress = storage.recipient(blockchainType: blockchainType)
        address = initialAddress?.raw
    }
}

extension AddressMultiSwapSettingsViewModel: IMultiSwapSettingsField {
    var syncPublisher: AnyPublisher<Void, Never> {
        syncSubject.eraseToAnyPublisher()
    }

    var state: BaseMultiSwapSettingsViewModel.FieldState {
        .init(valid: true, changed: address?.lowercased() != initialAddress?.raw.lowercased(), resetEnabled: address != nil)
    }

    func onReset() {
        address = nil
    }

    func onDone() {
        storage.set(recipient: address.map { Address(raw: $0) }, blockchainType: blockchainType)
    }
}
