import UIKit
import ThemeKit

struct InfoModule {

    private static func viewController(title: String, viewItems: [InfoViewModel.ViewItem]) -> UIViewController {
        let viewModel = InfoViewModel(title: title, viewItems: viewItems)
        let viewController = InfoViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension InfoModule {

    static func dexInfo(dex: SwapModule.Dex) -> UIViewController {
        let dexName = dex.provider.rawValue
        let blockchain = dex.blockchain.name

        return viewController(
                title: dex.provider.title,
                viewItems: [
                    .separator,
                    .text(string: "swap.dex_info.description".localized(dexName, blockchain, dexName)),
                    .header3Cell(string: "swap.dex_info.header_dex_related".localized(dexName)),
                    .header(title: "swap.dex_info.header_allowance".localized),
                    .text(string: "swap.dex_info.content_allowance".localized),
                    .header(title: "swap.dex_info.header_price_impact".localized),
                    .text(string: "swap.dex_info.content_price_impact".localized),
                    .header(title: "swap.dex_info.header_swap_fee".localized),
                    .text(string: "swap.dex_info.content_swap_fee".localized),
                    .header(title: "swap.dex_info.header_guaranteed_amount".localized),
                    .text(string: "swap.dex_info.content_guaranteed_amount".localized),
                    .header(title: "swap.dex_info.header_maximum_spend".localized),
                    .text(string: "swap.dex_info.content_maximum_spend".localized),
                    .header3Cell(string: "swap.dex_info.header_other".localized),
                    .header(title: "swap.dex_info.header_transaction_fee".localized),
                    .text(string: "swap.dex_info.content_transaction_fee".localized(blockchain, dexName)),
                    .header(title: "swap.dex_info.header_transaction_speed".localized),
                    .text(string: "swap.dex_info.content_transaction_speed".localized),
                    .margin(height: .margin12),
                    .button(title: "swap.dex_info.link_button".localized(dexName), url: dex.provider.infoUrl)
                ]
        )
    }

    static var feeInfo: UIViewController {
        viewController(
                title: "send.fee_info.title".localized,
                viewItems: [
                    .separator,
                    .text(string: "send.fee_info.description".localized),
                    .header(title: "send.fee_info.header_slow".localized),
                    .text(string: "send.fee_info.content_slow".localized),
                    .header(title: "send.fee_info.header_average".localized),
                    .text(string: "send.fee_info.content_average".localized),
                    .header(title: "send.fee_info.header_fast".localized),
                    .text(string: "send.fee_info.content_fast".localized),
                    .margin(height: .margin24),
                    .text(string: "send.fee_info.content_conclusion".localized)
                ]
        )
    }

    static var timeLockInfo: UIViewController {
        viewController(
                title: "lock_info.title".localized,
                viewItems: [
                    .separator,
                    .text(string: "lock_info.text".localized)
                ]
        )
    }

    static var restoreSourceInfo: UIViewController {
        viewController(
                title: "blockchain_settings.info.title".localized,
                viewItems: [
                    .header(title: "blockchain_settings.info.restore_source".localized),
                    .text(string: "blockchain_settings.info.restore_source.content".localized),
                ]
        )
    }

    static var transactionInputsOutputsInfo: UIViewController {
        viewController(
                title: "blockchain_settings.info.title".localized,
                viewItems: [
                    .header(title: "blockchain_settings.info.transaction_inputs_outputs".localized),
                    .text(string: "blockchain_settings.info.transaction_inputs_outputs.content".localized),
                ]
        )
    }

    static var syncModeInfo: UIViewController {
        viewController(
                title: "blockchain_settings.info.title".localized,
                viewItems: [
                    .header(title: "blockchain_settings.info.sync_mode".localized),
                    .text(string: "blockchain_settings.info.sync_mode.content".localized),
                ]
        )
    }

}
