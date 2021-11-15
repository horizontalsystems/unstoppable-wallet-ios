import UIKit
import SnapKit
import ThemeKit
import SectionsTableView

class TermsViewController: ThemeViewController {
    private let delegate: ITermsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var terms = [Term]()

    init(delegate: ITermsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "terms.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: DescriptionCell.self)
        tableView.registerCell(forClass: TermsSeparatorCell.self)
        tableView.registerCell(forClass: CheckboxCell.self)
        tableView.registerCell(forClass: TermsFooterCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.sectionDataSource = self

        delegate.viewDidLoad()

        tableView.buildSections()
    }

    private func checkboxRow(index: Int, text: String, checked: Bool, isLast: Bool) -> RowProtocol {
        Row<CheckboxCell>(
                id: "checkbox_\(index)",
                hash: "\(checked)",
                autoDeselect: true,
                dynamicHeight: { containerWidth in
                    CheckboxCell.height(containerWidth: containerWidth, text: text, backgroundStyle: .lawrence)
                },
                bind: { cell, _ in
                    cell.bind(text: text, checked: checked, backgroundStyle: .lawrence, isFirst: index == 0, isLast: isLast)
                },
                action: { [weak self] _ in
                    self?.delegate.onTapTerm(index: index)
                }
        )
    }

}

extension TermsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "terms.description".localized

        return [
            Section(
                    id: "description",
                    headerState: .margin(height: .margin12),
                    rows: [
                        Row<DescriptionCell>(
                                id: "description",
                                dynamicHeight: { containerWidth in
                                    DescriptionCell.height(containerWidth: containerWidth, text: descriptionText)
                                },
                                bind: { cell, _ in
                                    cell.bind(text: descriptionText)
                                }
                        )
                    ]
            ),
            Section(
                    id: "terms",
                    headerState: .margin(height: .margin24),
                    rows: terms.enumerated().map { index, term in
                        checkboxRow(
                                index: index,
                                text: "terms.item.\(term.id)".localized,
                                checked: term.accepted,
                                isLast: index == terms.count - 1
                        )
                    }
            ),
            Section(
                    id: "footer",
                    rows: [
                        Row<TermsFooterCell>(
                                id: "footer",
                                dynamicHeight: { containerWidth in
                                    TermsFooterCell.height(containerWidth: containerWidth)
                                }
                        )
                    ]
            ),
            Section(
                    id: "brand",
                    headerState: .margin(height: .margin32),
                    rows: [
                        Row<BrandFooterCell>(
                                id: "brand",
                                dynamicHeight: { containerWidth in
                                    BrandFooterCell.height(containerWidth: containerWidth, title: BrandFooterCell.brandText)
                                },
                                bind: { cell, _ in
                                    cell.title = BrandFooterCell.brandText
                                }
                        )
                    ]
            )
        ]
    }

}

extension TermsViewController: ITermsView {

    func set(terms: [Term]) {
        self.terms = terms
    }

    func refresh() {
        tableView.reload()
    }

}
