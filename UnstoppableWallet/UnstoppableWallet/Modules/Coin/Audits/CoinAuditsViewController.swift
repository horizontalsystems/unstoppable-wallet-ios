import ComponentKit
import HUD
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class CoinAuditsViewController: ThemeViewController {
    private let viewModel: CoinAuditsViewModel
    private let urlManager: UrlManager

    private let tableView = SectionsTableView(style: .grouped)
    private let emptyView = PlaceholderView()

    init(viewModel: CoinAuditsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_analytics.audits".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: BrandFooterCell.self)

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.image = UIImage(named: "not_available_48")
        emptyView.text = "coin_analytics.audits.no_reports".localized
        emptyView.isHidden = !viewModel.viewItems.isEmpty

        tableView.reload()
    }

    private func open(url: String) {
        urlManager.open(url: url, from: self)
    }
}

extension CoinAuditsViewController: SectionsDataSource {
    private func headerRow(logoUrl: String?, name: String) -> RowProtocol {
        tableView.universalRow56(
            id: "header-\(name)",
            image: .url(logoUrl, placeholder: "placeholder_circle_32"),
            title: .body(name),
            backgroundStyle: .transparent
        )
    }

    private func row(auditViewItem: CoinAuditsViewModel.AuditViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        var elements: [CellBuilderNew.CellElement] = [
            .vStackCentered([
                .textElement(text: .body(auditViewItem.date)),
                .margin(1),
                .textElement(text: .subhead2(auditViewItem.name)),
            ]),
            .textElement(text: .subhead1(auditViewItem.issues, color: .themeGray), parameters: .rightAlignment),
        ]
        if auditViewItem.reportUrl != nil {
            elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(.disclosure))
        }
        return CellBuilderNew.row(
            rootElement: .hStack(elements),
            tableView: tableView,
            id: auditViewItem.name + (auditViewItem.reportUrl ?? ""),
            height: .heightDoubleLineCell,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
            },
            action: auditViewItem.reportUrl.map { url in
                { [weak self] in self?.open(url: url) }
            }
        )
    }

    private func poweredBySection(text: String) -> SectionProtocol {
        Section(
            id: "powered-by",
            headerState: .margin(height: .margin32),
            rows: [
                Row<BrandFooterCell>(
                    id: "powered-by",
                    dynamicHeight: { containerWidth in
                        BrandFooterCell.height(containerWidth: containerWidth, title: text)
                    },
                    bind: { cell, _ in
                        cell.title = text
                    }
                ),
            ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard !viewModel.viewItems.isEmpty else {
            return []
        }

        var sections = [SectionProtocol]()

        for (index, viewItem) in viewModel.viewItems.enumerated() {
            sections.append(contentsOf: [
                Section(
                    id: "header-\(index)",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin8),
                    rows: [
                        headerRow(logoUrl: viewItem.logoUrl, name: viewItem.name),
                    ]
                ),
                Section(
                    id: "audits-\(index)",
                    footerState: .margin(height: .margin12),
                    rows: viewItem.auditViewItems.enumerated().map { index, auditViewItem in
                        row(
                            auditViewItem: auditViewItem,
                            isFirst: index == 0,
                            isLast: index == viewItem.auditViewItems.count - 1
                        )
                    }
                ),
            ])
        }

        sections.append(poweredBySection(text: "Powered by Defiyield.app"))

        return sections
    }
}
