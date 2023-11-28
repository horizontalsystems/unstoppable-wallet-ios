import Foundation
import UIKit
import SwiftUI

class ReceiveAddressModule {

    static func view(wallet: Wallet) -> some View {
        let service = ReceiveAddressService(wallet: wallet, adapterManager: App.shared.adapterManager)
        let depositViewItemFactory = ReceiveAddressViewItemFactory()

        let viewModel = ReceiveAddressViewModel(service: service, viewItemFactory: depositViewItemFactory, decimalParser: AmountDecimalParser())
        return ReceiveAddressView<ReceiveAddressService, ReceiveAddressViewItemFactory>(viewModel: viewModel)
    }

}

extension ReceiveAddressModule {

    struct ErrorItem: Error {
        let icon: String
        let text: String
        let retryAction: (() -> ())?

        init(icon: String, text: String, retryAction: (() -> ())? = nil) {
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

        static func ==(lhs: PopupWarningItem, rhs: PopupWarningItem) -> Bool {
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
            case .amount: return "cex_deposit.set_amount".localized
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

    enum Item: Identifiable, Hashable {
        case qrItem(QrItem)
        case value(title: String, value: String, copyable: Bool)
        case infoValue(title: String, value: String, infoTitle: String, infoDescription: String, style: HighlightedDescriptionBaseView.Style = .yellow)
        case highlightedDescription(text: String, style: HighlightedDescriptionBaseView.Style = .yellow)

        public var id: String {
            switch self {
            case let .qrItem(item): return "\(item.address)_\(item.networkName ?? "NA")"
            case let .value(title, value, _): return title + value
            case let .infoValue(title, value, _, _, _): return title + value
            case let .highlightedDescription(text, _): return text
            }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func ==(lhs: Item, rhs: Item) -> Bool {
            lhs.id == rhs.id
        }
    }

    struct ViewItem {
        let copyValue: String
        let sections: [[Item]]
    }

}
