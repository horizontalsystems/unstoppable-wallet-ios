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

        tableView.registerCell(forClass: TermsHeaderCell.self)
        tableView.registerCell(forClass: DescriptionCell.self)
        tableView.registerCell(forClass: TermsButtonsCell.self)
        tableView.registerCell(forClass: CheckboxCell.self)
        tableView.registerCell(forClass: TermsFooterCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.sectionDataSource = self

        delegate.viewDidLoad()

        tableView.buildSections()
    }

    private func checkboxRow(index: Int, text: String, checked: Bool) -> RowProtocol {
        Row<CheckboxCell>(
                id: "checkbox_\(index)",
                hash: "\(checked)",
                dynamicHeight: { containerWidth in
                    CheckboxCell.height(containerWidth: containerWidth, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text, checked: checked)
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
                    id: "main",
                    rows: [
                        Row<TermsHeaderCell>(
                                id: "header",
                                height: TermsHeaderCell.height,
                                bind: { cell, _ in
                                    cell.bind(image: UIImage(named: "App Icon"), title: "Unstoppable", subtitle: "terms.app_subtitle".localized)
                                }
                        ),
                        Row<DescriptionCell>(
                                id: "description",
                                dynamicHeight: { containerWidth in
                                    DescriptionCell.height(containerWidth: containerWidth, text: descriptionText)
                                },
                                bind: { cell, _ in
                                    cell.bind(text: descriptionText)
                                }
                        ),
                        Row<TermsButtonsCell>(
                                id: "buttons",
                                height: TermsButtonsCell.height,
                                bind: { [weak self] cell, _ in
                                    cell.bind(onTapGithub: {
                                        self?.delegate.onTapGitHubButton()
                                    }, onTapSite: {
                                        self?.delegate.onTapSiteButton()
                                    })
                                }
                        )
                    ]
            ),
            Section(
                    id: "terms",
                    rows: terms.enumerated().map { index, term in
                        checkboxRow(
                                index: index,
                                text: "terms.item.\(term.id)".localized,
                                checked: term.accepted
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
                        ),
                        Row<BrandFooterCell>(
                                id: "brand",
                                dynamicHeight: { containerWidth in
                                    BrandFooterCell.height(containerWidth: containerWidth)
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
