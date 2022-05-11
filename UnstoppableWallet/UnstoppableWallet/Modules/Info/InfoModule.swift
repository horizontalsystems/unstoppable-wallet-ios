import UIKit
import ThemeKit

struct InfoModule {

    private static func viewController(viewItems: [ViewItem]) -> UIViewController {
        let viewController = InfoViewController(viewItems: viewItems, urlManager: UrlManager(inApp: true))
        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension InfoModule {

    enum ViewItem {
        case separator
        case margin(height: CGFloat)
        case header(text: String)
        case header2(text: String)
        case text(text: String)
        case button(text: String, url: String)
    }

    static var feeInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "send.fee_info.title".localized),
                    .text(text: "send.fee_info.description".localized),
                    .header(text: "send.fee_info.header_slow".localized),
                    .text(text: "send.fee_info.content_slow".localized),
                    .header(text: "send.fee_info.header_average".localized),
                    .text(text: "send.fee_info.content_average".localized),
                    .header(text: "send.fee_info.header_fast".localized),
                    .text(text: "send.fee_info.content_fast".localized),
                    .margin(height: .margin24),
                    .text(text: "send.fee_info.content_conclusion".localized)
                ]
        )
    }

    static var timeLockInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "lock_info.title".localized),
                    .text(text: "lock_info.text".localized)
                ]
        )
    }

    static var restoreSourceInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "blockchain_settings.info.restore_source".localized),
                    .text(text: "blockchain_settings.info.restore_source.content".localized),
                ]
        )
    }

    static var transactionInputsOutputsInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "blockchain_settings.info.transaction_inputs_outputs".localized),
                    .text(text: "blockchain_settings.info.transaction_inputs_outputs.content".localized),
                ]
        )
    }

    static var syncModeInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "blockchain_settings.info.sync_mode".localized),
                    .text(text: "blockchain_settings.info.sync_mode.content".localized),
                ]
        )
    }

    static var transactionStatusInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "status_info.title".localized),
                    .header(text: "status_info.pending.title".localized),
                    .text(text: "status_info.pending.content".localized),
                    .header(text: "status_info.processing.title".localized),
                    .text(text: "status_info.processing.content".localized),
                    .header(text: "status_info.completed.title".localized),
                    .text(text: "status_info.confirmed.content".localized),
                    .header(text: "status_info.failed.title".localized),
                    .text(text: "status_info.failed.content".localized)
                ]
        )
    }

}
