import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import SnapKit
import HUD
import Chart
import ComponentKit
import Down

class CoinOverviewViewController: ThemeViewController {
    private let viewModel: CoinOverviewViewModel
    private let chartViewModel: CoinChartViewModel
    private let markdownParser: CoinPageMarkdownParser
    private var urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private var viewItem: CoinOverviewViewModel.ViewItem?

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    /* Chart section */
    private let chartCell: ChartCell
    private let chartRow: StaticRow

    /* Description */
    private let descriptionTextCell = ReadMoreTextCell()

    weak var parentNavigationController: UINavigationController?

    init(viewModel: CoinOverviewViewModel, chartViewModel: CoinChartViewModel, configuration: ChartConfiguration, markdownParser: CoinPageMarkdownParser, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.chartViewModel = chartViewModel
        self.markdownParser = markdownParser
        self.urlManager = urlManager

        chartCell = ChartCell(viewModel: chartViewModel, touchDelegate: chartViewModel, viewOptions: ChartCell.coinChart, configuration: configuration)
        chartRow = StaticRow(
                cell: chartCell,
                id: "chartView",
                height: chartCell.cellHeight
        )

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        let wrapperView = UIView()

        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        wrapperView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        wrapperView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        tableView.showsVerticalScrollIndicator = false

        tableView.registerCell(forClass: PerformanceTableViewCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.registerCell(forClass: TextCell.self)

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }

        chartRow.onReady = { [weak chartCell] in chartCell?.onLoad() }

        viewModel.onLoad()
        chartViewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
        chartViewModel.retry()
    }

    private func sync(viewItem: CoinOverviewViewModel.ViewItem?) {
        self.viewItem = viewItem

        if viewItem != nil {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }

        tableView.reload()
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension CoinOverviewViewController {

    private func linkRow(id: String, image: String, title: String, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: tableView,
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: image)?.withTintColor(.themeGray)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    }
                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    }
                },
                action: action
        )
    }

    private func coinInfoSection(viewItem: CoinOverviewViewModel.CoinViewItem) -> SectionProtocol {
        Section(
                id: "coin-info",
                rows: [
                    CellBuilder.row(
                            elements: [.image24, .text, .text],
                            tableView: tableView,
                            id: "coin-info",
                            height: .heightCell48,
                            bind: { cell in
                                cell.set(backgroundStyle: .transparent, isFirst: true, isLast: false)
                                cell.selectionStyle = .none

                                cell.bind(index: 0) { (component: ImageComponent) in
                                    component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: viewItem.imagePlaceholderName))
                                }
                                cell.bind(index: 1) { (component: TextComponent) in
                                    component.font = .body
                                    component.textColor = .themeGray
                                    component.text = viewItem.name
                                }
                                cell.bind(index: 2) { (component: TextComponent) in
                                    component.font = .subhead1
                                    component.textColor = .themeGray
                                    component.text = viewItem.marketCapRank
                                }
                            }
                    )
                ]
        )
    }

    private var chartSection: SectionProtocol {
        Section(
                id: "chart",
                rows: [chartRow]
        )
    }

    private func descriptionSection(description: String) -> SectionProtocol {
        var rows: [RowProtocol] = [
            tableView.subtitleRow(text: "chart.about.header".localized)
        ]

        descriptionTextCell.contentText = try? markdownParser.attributedString(from: description)
        rows.append(
                StaticRow(
                        cell: descriptionTextCell,
                        id: "about_cell",
                        dynamicHeight: { [weak self] containerWidth in
                            self?.descriptionTextCell.cellHeight(containerWidth: containerWidth) ?? 0
                        }
                ))

        return Section(
                id: "description",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

    private func linksSection(guideUrl: URL?, links: [CoinOverviewViewModel.LinkViewItem]) -> SectionProtocol {
        var guideRows = [RowProtocol]()

        if let guideUrl = guideUrl {
            let isLast = links.isEmpty

            let guideRow = linkRow(
                    id: "guide",
                    image: "academy_1_20",
                    title: "coin_page.guide".localized,
                    isFirst: true,
                    isLast: isLast,
                    action: { [weak self] in
                        let module = MarkdownModule.viewController(url: guideUrl)
                        self?.parentNavigationController?.pushViewController(module, animated: true)
                    }
            )

            guideRows.append(guideRow)
        }

        return Section(
                id: "links",
                headerState: .margin(height: .margin12),
                rows: [tableView.subtitleRow(text: "coin_page.links".localized)] + guideRows + links.enumerated().map { index, link in
                    linkRow(
                            id: link.title,
                            image: link.iconName,
                            title: link.title,
                            isFirst: guideRows.isEmpty && index == 0,
                            isLast: index == links.count - 1,
                            action: { [weak self] in
                                self?.openLink(url: link.url)
                            }
                    )
                }
        )
    }

    private func openLink(url: String) {
        if url.hasPrefix("https://twitter.com/") {
            let account = url.stripping(prefix: "https://twitter.com/")

            if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
                UIApplication.shared.open(appUrl)
                return
            }
        }

        urlManager.open(url: url, from: parentNavigationController)
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

    private func performanceSection(viewItems: [[CoinOverviewViewModel.PerformanceViewItem]]) -> SectionProtocol {
        Section(
                id: "return_of_investments_section",
                headerState: .margin(height: .margin12),
                rows: [
                    Row<PerformanceTableViewCell>(
                            id: "return_of_investments_cell",
                            dynamicHeight: { _ in
                                PerformanceTableViewCell.height(viewItems: viewItems)
                            },
                            bind: { cell, _ in
                                cell.bind(viewItems: viewItems)
                            }
                    )
                ]
        )
    }

    private func categoriesSection(categories: [String]) -> SectionProtocol {
        let text = categories.joined(separator: ", ")

        return Section(
                id: "categories",
                headerState: .margin(height: .margin12),
                rows: [
                    tableView.subtitleRow(text: "coin_page.category".localized),
                    Row<TextCell>(
                            id: "categories",
                            dynamicHeight: { width in
                                TextCell.height(containerWidth: width, text: text)
                            },
                            bind: { cell, _ in
                                cell.contentText = text
                            }
                    )
                ]
        )
    }

    private func contractRow(viewItem: CoinOverviewViewModel.ContractViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .text, .secondaryCircleButton, .secondaryCircleButton],
                tableView: tableView,
                id: "contract-\(index)",
                height: .heightCell48,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.iconUrl, placeholder: nil)
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.lineBreakMode = .byTruncatingMiddle
                        component.text = viewItem.title
                    }

                    cell.bind(index: 2) { (component: SecondaryCircleButtonComponent) in
                        component.button.set(image: UIImage(named: "copy_20"))
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: viewItem.reference)
                        }
                    }

                    cell.bind(index: 3) { (component: SecondaryCircleButtonComponent) in
                        if let explorerUrl = viewItem.explorerUrl {
                            component.isHidden = false
                            component.button.set(image: UIImage(named: "globe_20"))
                            component.onTap = { [weak self] in
                                self?.urlManager.open(url: explorerUrl, from: self?.parentNavigationController)
                            }
                        } else {
                            component.isHidden = true
                        }
                    }
                }
        )
    }

    private func contractsSection(contracts: [CoinOverviewViewModel.ContractViewItem]) -> SectionProtocol {
        Section(
                id: "contract-info",
                headerState: .margin(height: .margin12),
                rows: [tableView.subtitleRow(text: "coin_page.contracts".localized)] +
                        contracts.enumerated().map { index, viewItem in
                            contractRow(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == contracts.count - 1)
                        }
        )
    }

    private func marketRow(id: String, title: String, badge: String?, text: String, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .margin8, .badge, .text],
                tableView: tableView,
                id: id,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                        component.setContentHuggingPriority(.required, for: .horizontal)
                    }
                    cell.bind(index: 1) { (component: BadgeComponent) in
                        component.badgeView.set(style: .small)

                        if let badge = badge {
                            component.badgeView.text = badge
                            component.isHidden = false
                        } else {
                            component.isHidden = true
                        }
                    }
                    cell.bind(index: 2) { (component: TextComponent) in
                        component.font = .subhead1
                        component.textColor = .themeLeah
                        component.text = text
                        component.textAlignment = .right
                    }
                }
        )
    }

    private func marketInfoSection(viewItem: CoinOverviewViewModel.ViewItem) -> SectionProtocol? {
        let datas = [
            viewItem.marketCap.map {
                (id: "market_cap", title: "coin_page.market_cap".localized, badge: viewItem.marketCapRank, text: $0)
            },
            viewItem.totalSupply.map {
                (id: "total_supply", title: "coin_page.total_supply".localized, badge: nil, text: $0)
            },
            viewItem.circulatingSupply.map {
                (id: "circulating_supply", title: "coin_page.circulating_supply".localized, badge: nil, text: $0)
            },
            viewItem.volume24h.map {
                (id: "volume24", title: "coin_page.trading_volume".localized, badge: nil, text: $0)
            },
            viewItem.dilutedMarketCap.map {
                (id: "diluted_m_cap", title: "coin_page.diluted_market_cap".localized, badge: nil, text: $0)
            },
            viewItem.tvl.map {
                (id: "tvl", title: "coin_page.tvl".localized, badge: nil, text: $0)
            },
            viewItem.genesisDate.map {
                (id: "genesis_date", title: "coin_page.genesis_date".localized, badge: nil, text: $0)
            }
        ].compactMap {
            $0
        }

        guard !datas.isEmpty else {
            return nil
        }

        let rows = datas.enumerated().map { index, tuple in
            marketRow(
                    id: tuple.id,
                    title: tuple.title,
                    badge: tuple.badge,
                    text: tuple.text,
                    isFirst: index == 0,
                    isLast: index == datas.count - 1
            )
        }


        return Section(
                id: "market_info_section",
                headerState: .margin(height: .margin12),
                rows: rows
        )
    }

}

extension CoinOverviewViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            sections.append(coinInfoSection(viewItem: viewItem.coinViewItem))
            sections.append(chartSection)

            if let marketInfoSection = marketInfoSection(viewItem: viewItem) {
                sections.append(marketInfoSection)
            }

            sections.append(performanceSection(viewItems: viewItem.performance))

            if let categories = viewItem.categories {
                sections.append(categoriesSection(categories: categories))
            }

            if let contracts = viewItem.contracts {
                sections.append(contractsSection(contracts: contracts))
            }

            if !viewItem.description.isEmpty {
                sections.append(descriptionSection(description: viewItem.description))
            }

            if viewItem.guideUrl != nil || !viewItem.links.isEmpty {
                sections.append(linksSection(guideUrl: viewItem.guideUrl, links: viewItem.links))
            }

            sections.append(poweredBySection(text: "Powered by CoinGecko API"))
        }

        return sections
    }

}
