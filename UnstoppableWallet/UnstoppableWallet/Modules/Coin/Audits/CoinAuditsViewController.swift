import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import HUD

class CoinAuditsViewController: ThemeViewController {
    private let viewModel: CoinAuditsViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let emptyView = PlaceholderView()
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems: [CoinAuditsViewModel.ViewItem]?

    init(viewModel: CoinAuditsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
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

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in
            self?.sync(viewItems: $0)
        }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItems: [CoinAuditsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if let viewItems = viewItems {
            tableView.bounces = true
            emptyView.isHidden = !viewItems.isEmpty
        } else {
            tableView.bounces = false
            emptyView.isHidden = true
        }

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
                .textElement(text: .subhead2(auditViewItem.name))
            ]),
            .textElement(text: .subhead1(auditViewItem.issues, color: .themeGray), parameters: .rightAlignment)
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
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItems = viewItems, !viewItems.isEmpty else {
            return []
        }

        var sections = [SectionProtocol]()

        for (index, viewItem) in viewItems.enumerated() {
            sections.append(contentsOf: [
                Section(
                        id: "header-\(index)",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: .margin8),
                        rows: [
                            headerRow(logoUrl: viewItem.logoUrl, name: viewItem.name)
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
                )
            ])
        }

        sections.append(poweredBySection(text: "Powered by Defiyield.app"))

        return sections
    }

}
