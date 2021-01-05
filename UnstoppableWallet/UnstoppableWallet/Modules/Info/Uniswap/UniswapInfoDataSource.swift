import Foundation

class UniswapInfoDataSource: InfoDataSource {
    let title = "swap.uniswap_info.title".localized

    var viewItems: [InfoViewModel.ViewItem] {
        [
            .separator,
            .text(string: "swap.uniswap_info.description".localized),
            .header3Cell(string: "swap.uniswap_info.header_uniswap_related".localized),
            .header(title: "swap.uniswap_info.header_allowance".localized),
            .text(string: "swap.uniswap_info.content_allowance".localized),
            .header(title: "swap.uniswap_info.header_price_impact".localized),
            .text(string: "swap.uniswap_info.content_price_impact".localized),
            .header(title: "swap.uniswap_info.header_swap_fee".localized),
            .text(string: "swap.uniswap_info.content_swap_fee".localized),
            .header(title: "swap.uniswap_info.header_guaranteed_amount".localized),
            .text(string: "swap.uniswap_info.content_guaranteed_amount".localized),
            .header(title: "swap.uniswap_info.header_maximum_spend".localized),
            .text(string: "swap.uniswap_info.content_maximum_spend".localized),
            .header3Cell(string: "swap.uniswap_info.header_other".localized),
            .header(title: "swap.uniswap_info.header_transaction_fee".localized),
            .text(string: "swap.uniswap_info.content_transaction_fee".localized),
            .header(title: "swap.uniswap_info.header_transaction_speed".localized),
            .text(string: "swap.uniswap_info.content_transaction_speed".localized),
            .margin(height: .margin12),
            .button(title: "swap.uniswap_info.link_button".localized, url: "https://uniswap.org/")
        ]
    }
}
