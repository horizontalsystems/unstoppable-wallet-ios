import SectionsTableView

class PrivacyInfoSectionDataSource: InfoDataSource {
    var rowsFactory: InfoRowsFactory

    init(rowsFactory: InfoRowsFactory) {
        self.rowsFactory = rowsFactory
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: rowsFactory.separatorHeaderState,
                    rows: [rowsFactory.row(text: "settings_privacy_info.description".localized)]
            ),
            Section(
                    id: "transactions",
                    headerState: rowsFactory.header(text: "settings_privacy_info.header_blockchain_transactions".localized),
                    rows: [rowsFactory.row(text: "settings_privacy_info.content_blockchain_transactions".localized)]
            ),
            Section(
                    id: "connection",
                    headerState: rowsFactory.header(text: "settings_privacy_info.header_blockchain_connection".localized),
                    rows: [rowsFactory.row(text: "settings_privacy_info.content_blockchain_connection".localized)]
            ),
            Section(
                    id: "restore",
                    headerState: rowsFactory.header(text: "settings_privacy_info.header_blockchain_restore".localized),
                    footerState: .margin(height: .margin32),
                    rows: [rowsFactory.row(text: "settings_privacy_info.content_blockchain_restore".localized)]
            )
        ]
    }

}
