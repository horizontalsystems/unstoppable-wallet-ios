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
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = ErrorView()

    private var viewItems = [CoinAuditsViewModel.ViewItem]()

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

        title = "coin_page.audits".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: BCell.self)
        tableView.registerCell(forClass: F2Cell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin16)
        }

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] in self?.sync(state: $0) }
    }

    private func sync(state: CoinAuditsViewModel.State) {
        tableView.isHidden = true
        spinner.isHidden = true
        errorView.isHidden = true

        switch state {
        case .loading:
            spinner.isHidden = false
            spinner.startAnimating()
        case .failed:
            errorView.text = "coin_page.audits.sync_error".localized
            errorView.isHidden = false
        case .loaded(let viewItems):
            if viewItems.isEmpty {
                errorView.text = "coin_page.audits.no_reports".localized
                errorView.isHidden = false
            } else {
                self.viewItems = viewItems

                tableView.reload()
                tableView.isHidden = false
            }
        }
    }

    private func open(url: String) {
        urlManager.open(url: url, from: self)
    }

}

extension CoinAuditsViewController: SectionsDataSource {

    private func headerRow(name: String) -> RowProtocol {
        Row<BCell>(
                id: "header-\(name)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none
                    cell.title = name
                }
        )
    }

    private func row(auditViewItem: CoinAuditsViewModel.AuditViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<F2Cell>(
                id: auditViewItem.reportUrl,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = auditViewItem.date
                    cell.subtitle = auditViewItem.name
                    cell.value = auditViewItem.issues
                },
                action: { [weak self] _ in
                    self?.open(url: auditViewItem.reportUrl)
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
        var sections = [SectionProtocol]()

        for (index, viewItem) in viewItems.enumerated() {
            sections.append(contentsOf: [
                Section(
                        id: "header-\(index)",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: .margin8),
                        rows: [
                            headerRow(name: viewItem.name)
                        ]
                ),
                Section(
                        id: "audits-\(index)",
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
