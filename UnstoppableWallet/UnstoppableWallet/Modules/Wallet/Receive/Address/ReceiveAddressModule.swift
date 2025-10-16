import Foundation
import SwiftUI
import UIKit

enum ReceiveAddressModule {
    struct ErrorItem: Error {
        let icon: String
        let text: String
        let retryAction: (() -> Void)?

        init(icon: String, text: String, retryAction: (() -> Void)? = nil) {
            self.icon = icon
            self.text = text
            self.retryAction = retryAction
        }
    }

    struct QrItem {
        let address: String
        let uri: String?
        let networkName: String?
    }

    struct DescriptionItem {
        let text: String
        let style: HighlightedTextView.Style
    }

    struct PopupWarningItem: Equatable, Identifiable {
        let title: String
        let description: DescriptionItem
        let mode: Mode

        static func == (lhs: PopupWarningItem, rhs: PopupWarningItem) -> Bool {
            lhs.title == rhs.title &&
                lhs.description.text == rhs.description.text
        }

        public var id: String {
            title + description.text
        }

        enum Mode {
            case done(title: String)
            case activateStellarAsset
        }
    }

    enum PopupWarning: Equatable {
        case none
        case item(PopupWarningItem)
    }

    enum ActionType: Equatable {
        case amount
        case share
        case copy

        var title: String {
            switch self {
            case .amount: return "deposit.set_amount".localized
            case .share: return "deposit.share_address".localized
            case .copy: return "deposit.copy_address".localized
            }
        }

        var icon: String {
            switch self {
            case .amount: return "edit_24"
            case .share: return "share_1_24"
            case .copy: return "copy_24"
            }
        }
    }

    struct HighlightedDescription {
        let text: String
        let style: HighlightedDescriptionBaseView.Style
    }

    enum AddressChain: Int, Comparable {
        case external
        case change

        var title: String {
            switch self {
            case .external: return "receive_used_addresses.external".localized
            case .change: return "receive_used_addresses.change".localized
            }
        }

        static func < (lhs: AddressChain, rhs: AddressChain) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    struct ViewItem {
        let copyValue: String
        let qrItem: QrItem
        let amount: String?
        let active: Bool
        let assetActivated: Bool
        let memo: String?
        let usedAddresses: [AddressChain: [UsedAddress]]?
        let caution: AlertCardViewItem?

        static func empty(address: String) -> Self {
            .init(
                copyValue: address,
                qrItem: .init(address: address, uri: nil, networkName: nil),
                amount: nil,
                active: true,
                assetActivated: true,
                memo: nil,
                usedAddresses: nil,
                caution: nil
            )
        }
    }
}

extension ReceiveAddressModule {
    static func addressProvider(wallet: Wallet) -> ICurrentAddressProvider {
        ReceiveAddressService(wallet: wallet, type: .legacy, adapterManager: Core.shared.adapterManager)
    }
}
