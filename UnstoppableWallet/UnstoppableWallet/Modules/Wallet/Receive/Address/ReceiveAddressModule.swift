import Foundation
import UIKit

class ReceiveAddressModule {

    static func viewController(wallet: Wallet) -> UIViewController? {
        let service = ReceiveAddressService(wallet: wallet, adapterManager: App.shared.adapterManager)
        let depositViewItemFactory = ReceiveAddressViewItemFactory()

        let viewModel = ReceiveAddressViewModel(service: service, viewItemFactory: depositViewItemFactory)
        let viewController = ReceiveAddressViewController(viewModel: viewModel)

        return viewController
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
        let text: String
    }

    struct DescriptionItem {
        let text: String
        let style: HighlightedDescriptionBaseView.Style
    }

    struct PopupWarningItem {
        let title: String
        let description: DescriptionItem
        let doneButtonTitle: String
    }

    enum Item {
        case qrItem(QrItem)
        case value(title: String, value: String, copyable: Bool)
        case infoValue(title: String, value: String, infoTitle: String, infoDescription: String, style: HighlightedDescriptionBaseView.Style = .yellow)
        case highlightedDescription(text: String, style: HighlightedDescriptionBaseView.Style = .yellow)
    }

    struct ViewItem {
        let address: String
        let popup: PopupWarningItem?
        let sections: [[Item]]
    }

}
