import Foundation

class ZCashReceiveAddressViewItemFactory: ReceiveAddressViewItemFactory {
    private let addressType: ZcashAdapter.ReceiveAddressType

    init(addressType: ZcashAdapter.ReceiveAddressType) {
        self.addressType = addressType
    }

    override func networkName(item _: BaseReceiveAddressService.AssetReceiveAddress) -> String {
        "deposit.zcash.title".localized + ": " + addressType.title
    }
}

extension ZcashAdapter.ReceiveAddressType {
    var title: String {
        switch self {
        case .shielded: return "deposit.address_type.unified".localized
        case .transparent: return "deposit.address_type.transparent".localized
        case .singleUseTransparent: return "deposit.address_type.single_use_transparent".localized
        }
    }
}
