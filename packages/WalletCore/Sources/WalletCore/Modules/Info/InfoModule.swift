import SwiftUI

enum InfoModule {
    static func present(viewItems: [ViewItem]) {
        Coordinator.shared.present { isPresented in
            InfoView(viewItems: viewItems, isPresented: isPresented)
        }
    }
}

extension InfoModule {
    enum ViewItem: Hashable {
        case header1(text: String)
        case header3(text: String)
        case text(text: String)
        case listItem(text: String)
    }

    static var timeLockInfo: [ViewItem] {
        [
            .header1(text: "lock_info.title".localized),
            .text(text: "lock_info.text".localized),
        ]
    }

    static var transactionStatusInfo: [ViewItem] {
        [
            .header1(text: "status_info.title".localized),
            .header3(text: "status_info.pending.title".localized),
            .text(text: "status_info.pending.content".localized(AppConfig.appName)),
            .header3(text: "status_info.processing.title".localized),
            .text(text: "status_info.processing.content".localized),
            .header3(text: "status_info.completed.title".localized),
            .text(text: "status_info.confirmed.content".localized),
            .header3(text: "status_info.failed.title".localized),
            .text(text: "status_info.failed.content".localized(AppConfig.appName)),
        ]
    }
}
