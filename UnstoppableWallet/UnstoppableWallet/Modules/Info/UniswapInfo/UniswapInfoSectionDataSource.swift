import SectionsTableView

class UniswapInfoSectionDataSource: InfoDataSource {
    var rowsFactory: InfoRowsFactory

    init(rowsFactory: InfoRowsFactory) {
        self.rowsFactory = rowsFactory
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: rowsFactory.separatorHeaderState,
                    rows: [
                        rowsFactory.row(text: "swap.uniswap_info.description".localized),
                        rowsFactory.header3Row(id: "uniswap_related", string: "swap.uniswap_info.header_uniswap_related".localized)
                    ]
            ),
            Section(
                    id: "allowance",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_allowance".localized),
                    rows: [rowsFactory.row(text: "swap.uniswap_info.content_allowance".localized)]
            ),
            Section(
                    id: "price_impact",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_price_impact".localized),
                    rows: [rowsFactory.row(text: "swap.uniswap_info.content_price_impact".localized)]
            ),
            Section(
                    id: "swap_fee",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_swap_fee".localized),
                    rows: [rowsFactory.row(text: "swap.uniswap_info.content_swap_fee".localized)]
            ),
            Section(
                    id: "guaranteed_amount",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_guaranteed_amount".localized),
                    rows: [rowsFactory.row(text: "swap.uniswap_info.content_guaranteed_amount".localized)]
            ),
            Section(
                    id: "maximum_spend",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_maximum_spend".localized),
                    rows: [
                        rowsFactory.row(text: "swap.uniswap_info.content_maximum_spend".localized),
                        rowsFactory.header3Row(id: "other", string: "swap.uniswap_info.header_other".localized)
                    ]
            ),
            Section(
                    id: "transaction_fee",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_transaction_fee".localized),
                    rows: [rowsFactory.row(text: "swap.uniswap_info.content_transaction_fee".localized)]
            ),
            Section(
                    id: "transaction_speed",
                    headerState: rowsFactory.header(text: "swap.uniswap_info.header_transaction_speed".localized),
                    rows: [rowsFactory.row(text: "swap.uniswap_info.content_transaction_speed".localized)]
            ),
            Section(
                    id: "swap_link_button",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: [rowsFactory.linkButtonRow(title: "swap.uniswap_info.link_button".localized)]
            )
        ]
    }

}
