import Combine
import Foundation
import RxSwift

class ZcashReceiveAddressSelectViewModel: ObservableObject {
    @Published private(set) var viewItems = [ViewItem]()

    init() {
        sync()
    }

    private func sync() {
        viewItems = [
            .init(title: "deposit.address_type.unified".localized, description: "deposit.address_type.unified.description".localized, addressType: .shielded),
            .init(title: "deposit.address_type.transparent".localized, description: "deposit.address_type.transparent.description".localized, addressType: .transparent),
        ]
    }
}

extension ZcashReceiveAddressSelectViewModel {
    struct ViewItem: Hashable, Identifiable {
        var id: String { addressType.title }

        let title: String
        let description: String
        let addressType: ZcashAdapter.AddressType
    }
}
