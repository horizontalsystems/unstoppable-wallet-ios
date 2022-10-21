import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView

class AlertViewController: ThemeActionSheetController {
    private let alertTitle: String
    private let delegate: IAlertViewDelegate?

    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    private var viewItems = [AlertViewItem]()

    init(alertTitle: String, delegate: IAlertViewDelegate?) {
        self.alertTitle = alertTitle
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false

        tableView.registerCell(forClass: AlertTitleCell.self)
        tableView.registerCell(forClass: AlertItemCell.self)
        tableView.sectionDataSource = self

        delegate?.onLoad()

        tableView.reload()
    }

    private var titleRow: RowProtocol {
        Row<AlertTitleCell>(
                id: "title",
                height: AlertTitleCell.height,
                bind: { [weak self] cell, _ in
                    cell.bind(text: self?.alertTitle)
                }
        )
    }

    private func itemRow(viewItem: AlertViewItem, index: Int) -> RowProtocol {
        Row<AlertItemCell>(
                id: "item_\(index)",
                hash: "\(viewItem.selected)",
                height: .heightCell48,
                bind: {  [weak self] cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = viewItem.text
                    cell.isSelected = viewItem.selected
                    cell.onSelect = {
                        self?.delegate?.onTapViewItem(index: index)
                    }
                }
        )
    }

}

extension AlertViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        rows.append(titleRow)
        rows.append(contentsOf: viewItems.enumerated().map { itemRow(viewItem: $1, index: $0) })

        return [Section(id: "main", rows: rows)]
    }

}

extension AlertViewController: IAlertView {

    func set(viewItems: [AlertViewItem]) {
        self.viewItems = viewItems
    }

}
