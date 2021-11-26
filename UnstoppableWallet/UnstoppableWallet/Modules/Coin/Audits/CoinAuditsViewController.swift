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
    private let emptyLabel = UILabel()
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = MarketListErrorView()

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

        title = "coin_page.audits".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: ACell.self)
        tableView.registerCell(forClass: F2Cell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.centerY.equalToSuperview()
        }

        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = .subhead2
        emptyLabel.textColor = .themeGray
        emptyLabel.text = "coin_page.audits.no_reports".localized

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.onTapRetry = { [weak self] in self?.viewModel.refresh() }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorView.text = error
                self?.errorView.isHidden = false
            } else {
                self?.errorView.isHidden = true
            }
        }
    }

    private func sync(viewItems: [CoinAuditsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if let viewItems = viewItems {
            tableView.bounces = true
            emptyLabel.isHidden = !viewItems.isEmpty
        } else {
            tableView.bounces = false
            emptyLabel.isHidden = true
        }

        tableView.reload()
    }

    private func open(url: String) {
        urlManager.open(url: url, from: self)
    }

}

extension CoinAuditsViewController: SectionsDataSource {

    private func headerRow(logoUrl: String?, name: String) -> RowProtocol {
        Row<ACell>(
                id: "header-\(name)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none
                    cell.title = name
                    cell.set(titleImageSize: .iconSize24)
                    cell.setTitleImage(urlString: logoUrl, placeholder: UIImage(named: "icon_placeholder_24"))
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
