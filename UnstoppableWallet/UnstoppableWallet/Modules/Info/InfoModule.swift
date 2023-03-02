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
    }

    static var feeInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "send.fee_info.title".localized),
                    .text(text: "send.fee_info.description".localized)
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
                    .header2(text: "send.transaction_inputs_outputs_info.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.description".localized),
                    .header(text: "send.transaction_inputs_outputs_info.shuffle.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.shuffle.description".localized),
                    .header(text: "send.transaction_inputs_outputs_info.deterministic.title".localized),
                    .text(text: "send.transaction_inputs_outputs_info.deterministic.description".localized),
                ]
        )
    }

    static var rpcSourceInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "blockchain_settings.info.rpc_source".localized),
                    .text(text: "blockchain_settings.info.rpc_source.content".localized),
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

    static var tokenLiquidityInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "coin_page.token_liquidity".localized),
                    .text(text: "coin_page.token_liquidity.description".localized),
                    .header(text: "coin_page.dex_volume.title".localized),
                    .text(text: "coin_page.dex_volume.description".localized),
                    .header(text: "coin_page.dex_liquidity".localized),
                    .text(text: "coin_page.dex_liquidity.description".localized)
                ]
        )
    }

    static var tokenDistributionInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "coin_page.token_distribution".localized),
                    .text(text: "coin_page.token_distribution.description".localized),
                    .header(text: "coin_page.tx_count.title".localized),
                    .text(text: "coin_page.tx_count.description".localized),
                    .header(text: "coin_page.tx_volume.title".localized),
                    .text(text: "coin_page.tx_volume.description".localized),
                    .header(text: "coin_page.active_addresses".localized),
                    .text(text: "coin_page.active_addresses.description".localized),
                    .header(text: "coin_page.major_holders".localized),
                    .text(text: "coin_page.major_holders.description".localized)
                ]
        )
    }

    static var tokenTvlInfo: UIViewController {
        viewController(
                viewItems: [
                    .header2(text: "coin_page.token_tvl".localized),
                    .text(text: "coin_page.token_tvl.description".localized),
                    .header(text: "coin_page.tvl_rank".localized),
                    .text(text: "coin_page.tvl_rank.description".localized),
                    .header(text: "coin_page.market_cap_tvl_ratio".localized),
                    .text(text: "coin_page.market_cap_tvl_ratio.description".localized)
                ]
        )
    }

}
