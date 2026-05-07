import Foundation

class ZCashReceiveAddressViewItemFactory: ReceiveAddressViewItemFactory {
    private let addressType: ZcashAdapter.AddressType

    init(addressType: ZcashAdapter.AddressType) {
        self.addressType = addressType
    }

    override func networkName(item _: BaseReceiveAddressService.AssetReceiveAddress) -> String {
        "deposit.zcash.title".localized + ": " + addressType.title
    }
}

extension ZcashAdapter.AddressType {
    var title: String {
        switch self {
        case .shielded: return "deposit.address_type.unified".localized
        case .transparent: return "deposit.address_type.transparent".localized
        }
    }
}
