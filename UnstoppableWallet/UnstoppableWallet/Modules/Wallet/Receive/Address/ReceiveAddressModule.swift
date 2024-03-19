import Foundation
import SwiftUI
import UIKit

enum ReceiveAddressModule {
    static func view(wallet: Wallet, onDismiss: (() -> Void)? = nil) -> some View {
        let service = ReceiveAddressService(wallet: wallet, adapterManager: App.shared.adapterManager)
        let depositViewItemFactory = ReceiveAddressViewItemFactory()

        let viewModel = ReceiveAddressViewModel(service: service, viewItemFactory: depositViewItemFactory, decimalParser: AmountDecimalParser())
        return ReceiveAddressView<ReceiveAddressService, ReceiveAddressViewItemFactory>(viewModel: viewModel, onDismiss: onDismiss)
    }
}

extension ReceiveAddressModule {
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
        let style: HighlightedDescriptionBaseView.Style
    }

    struct PopupWarningItem: Equatable, Identifiable {
        let title: String
        let description: DescriptionItem
        let doneButtonTitle: String

        static func == (lhs: PopupWarningItem, rhs: PopupWarningItem) -> Bool {
            lhs.title == rhs.title &&
                lhs.description.text == rhs.description.text
        }

        public var id: String {
            title + description.text
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
            case .share: return "cex_deposit.share_address".localized
            case .copy: return "cex_deposit.copy_address".localized
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

    enum AddressType: Int, Comparable {
        case external
        case change

        var title: String {
            switch self {
            case .external: return "receive_used_addresses.external".localized
            case .change: return "receive_used_addresses.change".localized
            }
        }

        static func < (lhs: AddressType, rhs: AddressType) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    struct ViewItem {
        let copyValue: String
        let highlightedDescription: HighlightedDescription?
        let qrItem: QrItem
        let amount: String?
        let active: Bool
        let memo: String?
        let usedAddresses: [AddressType: [UsedAddress]]?
    }
}
