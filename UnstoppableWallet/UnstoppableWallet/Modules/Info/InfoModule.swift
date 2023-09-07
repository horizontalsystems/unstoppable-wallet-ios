import SwiftUI
import UIKit
import ThemeKit

struct InfoModule {

    static func viewController(viewItems: [ViewItem]) -> UIViewController {
        let viewController = InfoViewController(viewItems: viewItems)
        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension InfoModule {

    enum ViewItem {
        case header1(text: String)
        case header3(text: String)
        case text(text: String)
        case listItem(text: String)
    }

    static var feeInfo: UIViewController {
        viewController(
                viewItems: [
                    .header1(text: "send.fee_info.title".localized),
                    .text(text: "send.fee_info.description".localized(AppConfig.appName))
                ]
        )
    }

    static var timeLockInfo: UIViewController {
        viewController(
                viewItems: [
                    .header1(text: "lock_info.title".localized),
                    .text(text: "lock_info.text".localized)
                ]
        )
    }

    static var restoreSourceInfo: some View {
        InfoView(
                viewItems: [
                    .header1(text: "blockchain_settings.info.restore_source".localized),
                    .text(text: "blockchain_settings.info.restore_source.content".localized(AppConfig.appName)),
                ]
        )
                .ignoresSafeArea()
    }

    static var transactionInputsOutputsInfo: UIViewController {
        viewController(
                viewItems: [
                    .header1(text: "send.transaction_inputs_outputs_info.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.description".localized(AppConfig.appName, AppConfig.appName)),
                    .header3(text: "send.transaction_inputs_outputs_info.shuffle.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.shuffle.description".localized),
                    .header3(text: "send.transaction_inputs_outputs_info.deterministic.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.deterministic.description".localized),
                ]
        )
    }

    static var rpcSourceInfo: UIViewController {
        viewController(
                viewItems: [
                    .header1(text: "blockchain_settings.info.rpc_source".localized),
                    .text(text: "blockchain_settings.info.rpc_source.content".localized(AppConfig.appName)),
                ]
        )
    }

    static var transactionStatusInfo: UIViewController {
        viewController(
                viewItems: [
                    .header1(text: "status_info.title".localized),
                    .header3(text: "status_info.pending.title".localized),
                    .text(text: "status_info.pending.content".localized(AppConfig.appName)),
                    .header3(text: "status_info.processing.title".localized),
                    .text(text: "status_info.processing.content".localized),
                    .header3(text: "status_info.completed.title".localized),
                    .text(text: "status_info.confirmed.content".localized),
                    .header3(text: "status_info.failed.title".localized),
                    .text(text: "status_info.failed.content".localized(AppConfig.appName))
                ]
        )
    }

}

struct InfoView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let viewItems: [InfoModule.ViewItem]

    func makeUIViewController(context: Context) -> UIViewController {
        InfoModule.viewController(viewItems: viewItems)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }

}
