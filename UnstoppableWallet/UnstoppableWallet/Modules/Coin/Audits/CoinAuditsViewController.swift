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
        CellBuilder.row(
                elements: [.image, .text],
                tableView: tableView,
                id: "header-\(name)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.setImage(urlString: logoUrl, placeholder: UIImage(named: "icon_placeholder_24"))
                    })

                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = name
                    })
                }
        )
    }

    private func row(auditViewItem: CoinAuditsViewModel.AuditViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        let bindBlock = { (cell: BaseThemeCell) in
            cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

            cell.bind(index: 0, block: { (component: MultiTextComponent) in
                component.set(style: .m1)
                component.title.set(style: .b2)
                component.subtitle.set(style: .d1)

                component.title.text = auditViewItem.date
                component.subtitle.text = auditViewItem.name
            })

            cell.bind(index: 1, block: { (component: TextComponent) in
                component.setContentHuggingPriority(.required, for: .horizontal)
                component.set(style: .c1)
                component.text = auditViewItem.issues
            })
        }

        if let reportUrl = auditViewItem.reportUrl {
            return CellBuilder.selectableRow(
                    elements: [.multiText, .text, .margin8, .image],
                    tableView: tableView,
                    id: reportUrl,
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell in
                        bindBlock(cell)

                        cell.bind(index: 2, block: { (component: ImageComponent) in
                            component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                        })
                    },
                    action: { [weak self] in
                        self?.open(url: reportUrl)
                    }
            )
        } else {
            return CellBuilder.row(
                    elements: [.multiText, .text],
                    tableView: tableView,
                    id: auditViewItem.name,
                    height: .heightDoubleLineCell,
                    bind: { cell in
                        bindBlock(cell)
                    }
            )
        }
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
