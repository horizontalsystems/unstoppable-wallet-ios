import SectionsTableView

class FeeInfoSectionsDataSource: InfoDataSource {
    var rowsFactory: InfoRowsFactory

    init(rowsFactory: InfoRowsFactory) {
        self.rowsFactory = rowsFactory
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: rowsFactory.separatorHeaderState,
                    rows: [rowsFactory.row(text: "send.fee_info.description".localized)]
            ),
            Section(
                    id: "slow",
                    headerState: rowsFactory.header(text: "send.fee_info.header_slow".localized),
                    rows: [rowsFactory.row(text: "send.fee_info.content_slow".localized)]
            ),
            Section(
                    id: "average",
                    headerState: rowsFactory.header(text: "send.fee_info.header_average".localized),
                    rows: [rowsFactory.row(text: "send.fee_info.content_average".localized)]
            ),
            Section(
                    id: "fast",
                    headerState: rowsFactory.header(text: "send.fee_info.header_fast".localized),
                    rows: [rowsFactory.row(text: "send.fee_info.content_fast".localized)]
            ),
            Section(
                    id: "conclusion",
                    headerState: .margin(height: .margin24),
                    rows: [rowsFactory.row(text: "send.fee_info.content_conclusion".localized)]
            )
        ]
    }

}
