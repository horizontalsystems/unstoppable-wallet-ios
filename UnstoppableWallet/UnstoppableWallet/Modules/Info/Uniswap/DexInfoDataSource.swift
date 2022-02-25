import Foundation

class DexInfoDataSource: InfoDataSource {
    private let dex: SwapModule.Dex

    init(dex: SwapModule.Dex) {
        self.dex = dex
    }

    private var dexName: String {
        dex.provider.rawValue
    }

    private var blockchain: String {
        dex.blockchain.name
    }

}

extension DexInfoDataSource {

    var title: String {
        dex.provider.title
    }

    var viewItems: [InfoViewModel.ViewItem] {
        [
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
    }

}
