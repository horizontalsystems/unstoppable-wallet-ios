import SectionsTableView

class TimeLockSectionDataSource: InfoDataSource {
    var rowsFactory: InfoRowsFactory

    init(rowsFactory: InfoRowsFactory) {
        self.rowsFactory = rowsFactory
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: rowsFactory.separatorHeaderState,
                    rows: [rowsFactory.row(text: "lock_info.text".localized)]
            )
        ]
    }

}
