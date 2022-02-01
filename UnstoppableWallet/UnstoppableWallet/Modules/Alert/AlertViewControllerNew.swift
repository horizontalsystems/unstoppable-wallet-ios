import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView

class AlertViewControllerNew: ThemeActionSheetController {
    private let alertTitle: String?
    private let viewItems: [ViewItem]
    private let reportAfterDismiss: Bool
    private let onSelect: (Int) -> ()

    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    private init(title: String?, viewItems: [ViewItem], reportAfterDismiss: Bool, onSelect: @escaping (Int) -> ()) {
        alertTitle = title
        self.viewItems = viewItems
        self.reportAfterDismiss = reportAfterDismiss
        self.onSelect = onSelect

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

        tableView.buildSections()
    }

    private func titleRow(text: String) -> RowProtocol {
        Row<AlertTitleCell>(
                id: "title",
                height: AlertTitleCell.height,
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func itemRow(viewItem: ViewItem, index: Int) -> RowProtocol {
        Row<AlertItemCell>(
                id: "item_\(index)",
                hash: "\(viewItem.selected)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.title = viewItem.text
                    cell.isSelected = viewItem.selected
                    cell.onSelect = { [weak self] in
                        self?.handleSelect(index: index)
                    }
                }
        )
    }

    private func handleSelect(index: Int) {
        if reportAfterDismiss {
            dismiss(animated: true) { [weak self] in
                self?.onSelect(index)
            }
        } else {
            onSelect(index)
            dismiss(animated: true)
        }
    }

}

extension AlertViewControllerNew: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        if let title = alertTitle {
            rows.append(titleRow(text: title))
        }

        rows.append(contentsOf: viewItems.enumerated().map { itemRow(viewItem: $1, index: $0) })

        return [Section(id: "main", rows: rows)]
    }

}

extension AlertViewControllerNew {

    struct ViewItem {
        let text: String
        let selected: Bool

        init(text: String, selected: Bool = false) {
            self.text = text
            self.selected = selected
        }
    }

}

extension AlertViewControllerNew {

    static func instance(title: String? = nil, viewItems: [ViewItem], reportAfterDismiss: Bool = false, onSelect: @escaping (Int) -> ()) -> UIViewController {
        let controller = AlertViewControllerNew(title: title, viewItems: viewItems, reportAfterDismiss: reportAfterDismiss, onSelect: onSelect)
        return controller.toAlert
    }

}
