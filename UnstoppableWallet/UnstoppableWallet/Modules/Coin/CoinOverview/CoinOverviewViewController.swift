import Chart
import ComponentKit
import Down
import HUD
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class CoinOverviewViewController: ThemeViewController {
    private let viewModel: CoinOverviewViewModel
    private let chartViewModel: CoinChartViewModel
    private let chartRouter: ChartIndicatorRouter
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

    private let chartConfigurationCell = BaseThemeCell()
    private let chartConfigurationRow: StaticRow
    private var chartIndicatorShown: Bool = true

    /* Description */
    private let descriptionTextCell = ReadMoreTextCell()

    weak var parentNavigationController: UINavigationController?

    init(viewModel: CoinOverviewViewModel, chartViewModel: CoinChartViewModel, chartRouter: ChartIndicatorRouter, markdownParser: CoinPageMarkdownParser, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.chartViewModel = chartViewModel
        self.chartRouter = chartRouter
        self.markdownParser = markdownParser
        self.urlManager = urlManager

        chartCell = ChartCell(viewModel: chartViewModel, configuration: .coinChart)
        chartRow = StaticRow(
            cell: chartCell,
            id: "chartView",
            height: chartCell.cellHeight
        )

        chartConfigurationRow = StaticRow(
            cell: chartConfigurationCell,
            id: "chartConfiguration",
            height: .heightCell48
        )

        super.init()

        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        subscribe(disposeBag, chartViewModel.indicatorsShownDriver) { [weak self] isShown in
            self?.chartIndicatorShown = isShown
            self?.syncChartConfigurationCell()
        }
        subscribe(disposeBag, chartViewModel.openSettingsSignal) { [weak self] in
            self?.openChartSettings()
        }
        subscribe(disposeBag, viewModel.hudSignal) {
            HudHelper.instance.show(banner: $0)
        }

        chartRow.onReady = { [weak chartCell] in chartCell?.onLoad() }

        chartConfigurationCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        syncChartConfigurationCell()

        viewModel.onLoad()
        chartViewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

    private func syncChartConfigurationCell() {
        CellBuilderNew.buildStatic(
            cell: chartConfigurationCell,
            rootElement: .hStack([
                .textElement(text: .body("coin_overview.indicators".localized)),
                .secondaryButton { [weak self] component in
                    component.isHidden = false
                    component.button.set(style: .default)
                    let title = (self?.chartIndicatorShown ?? false) ? "coin_overview.indicators.hide".localized : "coin_overview.indicators.show".localized
                    component.button.setTitle(title, for: .normal)
                    component.onTap = {
                        self?.chartViewModel.onToggleIndicators()
                    }
                },
                .margin(8),
                .secondaryCircleButton { component in
                    component.isHidden = false
                    component.button.set(image: UIImage(named: "setting_20"))
                    component.button.isEnabled = true
                    component.onTap = { [weak self] in
                        self?.chartViewModel.onTapChartSettings()
                    }
                },
                .image24 { component in
                    component.isHidden = true
                    component.imageView.image = UIImage(named: "lock_24")
                },
            ])
        )
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func openChartSettings() {
        parentNavigationController?.present(chartRouter.viewController(), animated: true)
    }
}

extension CoinOverviewViewController {
    private func linkRow(id: String, image: String, title: String, isFirst: Bool, isLast: Bool, action: @escaping () -> Void) -> RowProtocol {
        tableView.universalRow48(
            id: id,
            image: .local(UIImage(named: image)?.withTintColor(.themeGray)),
            title: .body(title),
            accessoryType: .disclosure,
            autoDeselect: true,
            isFirst: isFirst,
            isLast: isLast,
            action: action
        )
    }

    private func coinInfoSection(viewItem: CoinOverviewViewModel.CoinViewItem) -> SectionProtocol {
        Section(
            id: "coin-info",
            rows: [
                tableView.universalRow56(
                    id: "coin-info",
                    image: .url(viewItem.imageUrl, placeholder: viewItem.imagePlaceholderName),
                    title: .body(viewItem.name, color: .themeGray),
                    value: .subhead1(viewItem.marketCapRank, color: .themeGray),
                    backgroundStyle: .transparent,
                    isFirst: true,
                    isLast: false
                ),
            ]
        )
    }

    private var chartSection: SectionProtocol {
        Section(
            id: "chart",
            rows: [chartRow]
        )
    }

    private func descriptionSection(description: String) -> SectionProtocol? {
        guard let attributedText = try? markdownParser.attributedString(from: description) else {
            return nil
        }

        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let layoutMargins = UIEdgeInsets(top: .margin12, left: .margin16, bottom: .margin12, right: .margin16)

        let descriptionWarning = "coin_overview.description_warning".localized
        let descriptionWarningFont: UIFont = .subhead2
        let descriptionWarningPadding: CGFloat = .margin24

        return Section(
            id: "description",
            headerState: .margin(height: .margin12),
            rows: [
                tableView.subtitleRow(text: "coin_overview.overview".localized),
                CellBuilderNew.row(
                    rootElement: .vStack([
                        .text { component in
                            component.attributedText = attributedText
                            component.numberOfLines = 0
                        },
                        .margin(descriptionWarningPadding),
                        .text { component in
                            component.font = descriptionWarningFont
                            component.textColor = .themeJacob
                            component.numberOfLines = 0
                            component.text = descriptionWarning
                        },
                    ]),
                    layoutMargins: layoutMargins,
                    tableView: tableView,
                    id: "description",
                    dynamicHeight: { containerWidth in
                        let textWidth = containerWidth - BaseThemeCell.margin(backgroundStyle: backgroundStyle).width - layoutMargins.width
                        return attributedText.height(containerWidth: textWidth)
                            + descriptionWarningPadding
                            + descriptionWarning.height(forContainerWidth: textWidth, font: descriptionWarningFont)
                            + layoutMargins.height
                    },
                    bind: { cell in
                        cell.set(backgroundStyle: backgroundStyle, isFirst: true, isLast: true)
                    }
                ),
            ]
        )
    }

    private func linksSection(guideUrl: URL?, links: [CoinOverviewViewModel.LinkViewItem]) -> SectionProtocol {
        var guideRows = [RowProtocol]()

        if let guideUrl = guideUrl {
            let isLast = links.isEmpty

            let guideRow = linkRow(
                id: "guide",
                image: "academy_1_24",
                title: "coin_overview.guide".localized,
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
            rows: [tableView.subtitleRow(text: "coin_overview.links".localized)] + guideRows + links.enumerated().map { index, link in
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
                ),
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
                ),
            ]
        )
    }

    private func typeRow(viewItem: CoinOverviewViewModel.TypeViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        var action: (() -> Void)?

        if let reference = viewItem.reference {
            action = {
                CopyHelper.copyAndNotify(value: reference)
            }
        }

        return CellBuilderNew.row(
            rootElement: .hStack([
                .imageElement(image: .url(viewItem.iconUrl, placeholder: "placeholder_rectangle_32"), size: .image32),
                .vStackCentered([
                    .textElement(text: .body(viewItem.title)),
                    .margin(1),
                    .textElement(text: .subhead2(viewItem.subtitle), parameters: .truncatingMiddle),
                ]),
                .secondaryCircleButton { [weak self] component in
                    component.isHidden = !viewItem.showAdd
                    component.button.set(image: UIImage(named: "add_to_wallet_2_20"))
                    component.onTap = {
                        self?.viewModel.onTapAddToWallet(index: index)
                    }
                },
                .secondaryCircleButton { [weak self] component in
                    component.isHidden = !viewItem.showAdded
                    component.button.set(image: UIImage(named: "filled_wallet_20"))
                    component.button.isSelected = true
                    component.onTap = {
                        self?.viewModel.onTapAddedToWallet(index: index)
                    }
                },
                .secondaryCircleButton { [weak self] component in
                    if let explorerUrl = viewItem.explorerUrl {
                        component.isHidden = false
                        component.button.set(image: UIImage(named: "globe_20"))
                        component.onTap = {
                            self?.urlManager.open(url: explorerUrl, from: self?.parentNavigationController)
                        }
                    } else {
                        component.isHidden = true
                    }
                },
            ]),
            tableView: tableView,
            id: "type-\(index)",
            height: .heightDoubleLineCell,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
            },
            action: action
        )
    }

    private func typesSection(typesViewItem: CoinOverviewViewModel.TypesViewItem) -> SectionProtocol {
        var rows: [RowProtocol] = [
            tableView.subtitleRow(text: typesViewItem.title),
        ]

        for (index, viewItem) in typesViewItem.viewItems.enumerated() {
            rows.append(
                typeRow(
                    viewItem: viewItem,
                    index: index,
                    isFirst: index == 0,
                    isLast: typesViewItem.action != nil ? false : index == typesViewItem.viewItems.count - 1
                )
            )
        }

        if let action = typesViewItem.action {
            rows.append(
                CellBuilderNew.row(
                    rootElement: .textElement(text: .body(action.title), parameters: .centerAlignment),
                    tableView: tableView,
                    id: "action",
                    hash: "\(action.rawValue)",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell in
                        cell.set(backgroundStyle: .lawrence, isLast: true)
                    },
                    action: { [weak self] in
                        self?.viewModel.onTap(typesAction: action)
                    }
                )
            )
        }

        return Section(
            id: "types",
            headerState: .margin(height: .margin12),
            rows: rows
        )
    }

    private func marketRow(id: String, title: String, badge: String?, text: String, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
            rootElement: .hStack([
                .textElement(text: .subhead2(title), parameters: .highHugging),
                .margin8,
                .badge { (component: BadgeComponent) in
                    component.badgeView.set(style: .small)

                    if let badge = badge {
                        component.badgeView.text = badge
                        component.isHidden = false
                    } else {
                        component.isHidden = true
                    }
                },
                .textElement(text: .subhead1(text), parameters: .rightAlignment),
            ]),
            tableView: tableView,
            id: id,
            height: .heightCell48,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
            }
        )
    }

    private func marketInfoSection(viewItem: CoinOverviewViewModel.ViewItem) -> SectionProtocol? {
        let datas = [
            viewItem.marketCap.map {
                (id: "market_cap", title: "coin_overview.market_cap".localized, badge: viewItem.marketCapRank, text: $0)
            },
            viewItem.totalSupply.map {
                (id: "total_supply", title: "coin_overview.total_supply".localized, badge: nil, text: $0)
            },
            viewItem.circulatingSupply.map {
                (id: "circulating_supply", title: "coin_overview.circulating_supply".localized, badge: nil, text: $0)
            },
            viewItem.volume24h.map {
                (id: "volume24", title: "coin_overview.trading_volume".localized, badge: nil, text: $0)
            },
            viewItem.dilutedMarketCap.map {
                (id: "diluted_m_cap", title: "coin_overview.diluted_market_cap".localized, badge: nil, text: $0)
            },
            viewItem.genesisDate.map {
                (id: "genesis_date", title: "coin_overview.genesis_date".localized, badge: nil, text: $0)
            },
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
            sections.append(
                Section(
                    id: "chart-configuration",
                    headerState: .margin(height: .margin12),
                    rows: [
                        chartConfigurationRow,
                    ]
                )
            )

            if let marketInfoSection = marketInfoSection(viewItem: viewItem) {
                sections.append(marketInfoSection)
            }

            sections.append(performanceSection(viewItems: viewItem.performance))

            if let types = viewItem.types {
                sections.append(typesSection(typesViewItem: types))
            }

            if !viewItem.description.isEmpty, let descriptionSection = descriptionSection(description: viewItem.description) {
                sections.append(descriptionSection)
            }

            if viewItem.guideUrl != nil || !viewItem.links.isEmpty {
                sections.append(linksSection(guideUrl: viewItem.guideUrl, links: viewItem.links))
            }

            sections.append(poweredBySection(text: "Powered by CoinGecko API"))
        }

        return sections
    }
}
