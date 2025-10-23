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

        class Mode {}
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

    struct ViewItem {
        let copyValue: String
        let highlightedDescription: HighlightedDescription?
        let qrItem: QrItem
        let amount: String?

        static func empty(address: String) -> Self {
            .init(
                copyValue: address,
                highlightedDescription: nil,
                qrItem: .init(address: address, uri: nil, networkName: nil),
                amount: nil,
            )
        }
    }
}

extension ReceiveAddressModule {
    static func addressProvider(wallet: Wallet) -> ICurrentAddressProvider {
        BaseReceiveAddressService(wallet: wallet)
    }

    @ViewBuilder static func instance(wallet: Wallet, path: Binding<NavigationPath>, onDismiss: (() -> Void)? = nil) -> some View {
        switch wallet.token.blockchainType {
        case .bitcoin, .bitcoinCash, .litecoin, .dash, .ecash: HDReceiveAddressView(wallet: wallet, onDismiss: onDismiss)
        case .tron: TronReceiveAddressView(wallet: wallet, onDismiss: onDismiss)
        case .stellar: StellarReceiveAddressView(wallet: wallet, onDismiss: onDismiss)
        case .monero: MoneroReceiveAddressView(wallet: wallet, onDismiss: onDismiss)
        case .zcash: ZcashReceiveAddressSelectView(wallet: wallet, path: path, onDismiss: onDismiss)
        default:
            let service = BaseReceiveAddressService(wallet: wallet)
            let viewModel = BaseReceiveAddressViewModel(service: service, viewItemFactory: ReceiveAddressViewItemFactory(), decimalParser: AmountDecimalParser())

            BaseReceiveAddressView(viewModel: viewModel, content: {}, onDismiss: onDismiss)
        }
    }
}
