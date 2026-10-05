import Foundation
import XrpKit

extension XrpKit.AddressError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFormat: return "send.address.invalid_address".localized
        case .networkMismatch: return "send.xrp.address_error.network_mismatch".localized
        case .tagConflict: return "send.xrp.destination_tag.conflict".localized
        }
    }
}
