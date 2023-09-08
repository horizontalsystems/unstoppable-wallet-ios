import ActionSheet
import ComponentKit
import SectionsTableView
import ThemeKit
import UIKit

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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

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
        let defaultColor: UIColor = viewItem.disabled ? .themeGray50 : .themeLeah

        var elements = [CellBuilderNew.CellElement]()
        var verticalTexts = [CellBuilderNew.CellElement]()
        verticalTexts.append(
            .textElement(
                text: .body(viewItem.text, color: viewItem.selected ? .themeJacob : defaultColor),
                parameters: .centerAlignment
            )
        )
        if let description = viewItem.description {
            verticalTexts.append(.margin(1))
            verticalTexts.append(
                .textElement(
                    text: .subhead2(description),
                    parameters: .centerAlignment
                )
            )
        }
        elements.append(.vStackCentered(verticalTexts))

        return CellBuilderNew.row(
            rootElement: .hStack(elements),
            tableView: tableView,
            id: "item_\(index)",
            height: viewItem.description == nil ? .heightCell48 : .heightDoubleLineCell,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .transparent)
            },
            action: {  [weak self] in
                self?.delegate?.onTapViewItem(index: index)
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
