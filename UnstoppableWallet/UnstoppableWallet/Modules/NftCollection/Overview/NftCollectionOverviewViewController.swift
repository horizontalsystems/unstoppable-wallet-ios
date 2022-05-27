import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class NftCollectionOverviewViewController: ThemeViewController {
    private let viewModel: NftCollectionOverviewViewModel
    private var urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderView()
    private let descriptionTextCell = ReadMoreTextCell()

    private var viewItem: NftCollectionOverviewViewModel.ViewItem?

    weak var parentNavigationController: UINavigationController?

    init(viewModel: NftCollectionOverviewViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        errorView.configureSyncError(target: self, action: #selector(onRetry))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: LogoHeaderCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.registerCell(forClass: ChartMarketCardCell<NftChartMarketCardView>.self)
        tableView.registerCell(forClass: MarketCardCell<MarketCardView>.self)

        tableView.showsVerticalScrollIndicator = false

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
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

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func sync(viewItem: NftCollectionOverviewViewModel.ViewItem?) {
        self.viewItem = viewItem

        if viewItem != nil {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }

        tableView.reload()
    }

    private func linkTitle(type: NftCollectionOverviewViewModel.LinkType) -> String {
        switch type {
        case .website: return "nft_collection.overview.links.website".localized
        case .openSea: return "OpenSea"
        case .discord: return "Discord"
        case .twitter: return "Twitter"
        }
    }

    private func linkIcon(type: NftCollectionOverviewViewModel.LinkType) -> UIImage? {
        switch type {
        case .website: return UIImage(named: "globe_20")
        case .openSea: return UIImage(named: "open_sea_20")
        case .discord: return UIImage(named: "discord_20")
        case .twitter: return UIImage(named: "twitter_20")
        }
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

}

extension NftCollectionOverviewViewController: SectionsDataSource {

    private func logoHeaderRow(viewItem: NftCollectionOverviewViewModel.ViewItem) -> RowProtocol {
        Row<LogoHeaderCell>(
                id: "logo-header",
                height: LogoHeaderCell.height,
                bind: { cell, _ in
                    cell.set(imageUrl: viewItem.logoImageUrl)
                    cell.title = viewItem.name
                }
        )
    }

    private func headerRow(title: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text],
                tableView: tableView,
                id: "header-\(title)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                }
        )
    }

    private func chartSection(statCharts: NftCollectionOverviewViewModel.StatChartViewItem) -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        let counters = [
            statCharts.ownerCount.map { (title: "nft_collection.overview.owners".localized, value: $0) },
            statCharts.itemCount.map { (title: "nft_collection.overview.items".localized, value: $0) }
        ].compactMap { $0 }

        let charts = [
            statCharts.oneDayVolumeItems,
            statCharts.oneDaySalesItems,
            statCharts.floorPriceItems,
            statCharts.averagePriceItems
        ].compactMap { $0 }

        if !counters.isEmpty {
            let row = Row<MarketCardCell<MarketCardView>>(
                    id: "count_row",
                    height: MarketCardView.viewHeight(),
                    bind: { cell, _ in
                        cell.clear()
                        if let viewItem = counters.at(index: 0) {
                            cell.append(viewItem: MarketCardView.ViewItem(title: viewItem.title, value: viewItem.value, diff: nil, diffColor: nil))
                        }
                        if let viewItem = counters.at(index: 1) {
                            cell.append(viewItem: MarketCardView.ViewItem(title: viewItem.title, value: viewItem.value, diff: nil, diffColor: nil))
                        }
                    }
            )
            sections.append(
                    Section(
                            id: "count_section",
                            footerState: .margin(height: charts.isEmpty ? .margin24 : .margin8),
                            rows: [row]
                    )
            )
        }

        guard !charts.isEmpty else {
            return sections
        }

        let topChartRow = Row<ChartMarketCardCell<NftChartMarketCardView>>(
                    id: "top_chart_row",
                    height: NftChartMarketCardView.viewHeight(),
                    bind: { cell, _ in
                        cell.clear()
                        cell.set(configuration: .chartPreview)
                        if let viewItem = charts.at(index: 0) {
                            cell.append(viewItem: viewItem)
                        }
                        if let viewItem = charts.at(index: 1) {
                            cell.append(viewItem: viewItem)
                        }
                    }
        )
        let hasBottomRow = charts.count > 2
        sections.append(
                Section(
                        id: "top_chart_section",
                        footerState: .margin(height: hasBottomRow ? .margin8 : .margin24),
                        rows: [topChartRow]
                )
        )

        if hasBottomRow {
            let bottomChartRow = Row<ChartMarketCardCell<NftChartMarketCardView>>(
                    id: "bottom_chart_row",
                    height: NftChartMarketCardView.viewHeight(),
                    bind: { cell, _ in
                        cell.clear()
                        cell.set(configuration: .chartPreview)
                        if let viewItem = charts.at(index: 2) {
                            cell.append(viewItem: viewItem)
                        }
                        if let viewItem = charts.at(index: 3) {
                            cell.append(viewItem: viewItem)
                        }
                    }
            )
            sections.append(
                    Section(
                            id: "bottom_chart_section",
                            footerState: .margin(height: .margin24),
                            rows: [bottomChartRow]
                    )
            )
        }

        return sections
    }

    private func descriptionSection(description: String) -> SectionProtocol {
        descriptionTextCell.contentText = NSAttributedString(string: description, attributes: [.font: UIFont.subhead2, .foregroundColor: UIColor.themeGray])

        let descriptionRow = StaticRow(
                cell: descriptionTextCell,
                id: "description",
                dynamicHeight: { [weak self] containerWidth in
                    self?.descriptionTextCell.cellHeight(containerWidth: containerWidth) ?? 0
                }
        )

        return Section(
                id: "description",
                footerState: .margin(height: .margin24),
                rows: [
                    headerRow(title: "nft_collection.overview.description".localized),
                    descriptionRow
                ]
        )
    }

    private func contractsSection(viewItems: [NftCollectionOverviewViewModel.ContractViewItem]) -> SectionProtocol {
        Section(
                id: "contracts",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin24),
                rows: [
                    headerRow(title: "nft_collection.overview.contracts".localized)
                ] + viewItems.enumerated().map { index, viewItem in
                    CellBuilder.row(
                            elements: [.image24, .text, .secondaryCircleButton, .secondaryCircleButton],
                            tableView: tableView,
                            id: "contract-\(index)",
                            height: .heightCell48,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == viewItems.count - 1)

                                cell.bind(index: 0) { (component: ImageComponent) in
                                    component.imageView.image = UIImage(named: viewItem.iconName)
                                }

                                cell.bind(index: 1) { (component: TextComponent) in
                                    component.set(style: .d1)
                                    component.text = viewItem.reference
                                }

                                cell.bind(index: 2) { (component: SecondaryCircleButtonComponent) in
                                    component.button.set(image: UIImage(named: "copy_20"))
                                    component.onTap = {
                                        UIPasteboard.general.setValue(viewItem.reference, forPasteboardType: "public.plain-text")
                                        HudHelper.instance.showSuccess(title: "alert.copied".localized)
                                    }
                                }

                                cell.bind(index: 3) { (component: SecondaryCircleButtonComponent) in
                                    component.button.set(image: UIImage(named: "globe_20"))
                                    component.onTap = { [weak self] in
                                        self?.urlManager.open(url: viewItem.explorerUrl, from: self?.parentNavigationController)
                                    }
                                }
                            }
                    )
                }
        )
    }

    private func linksSections(viewItems: [NftCollectionOverviewViewModel.LinkViewItem]) -> [SectionProtocol] {
        [
            Section(
                    id: "links-header",
                    rows: [
                        headerRow(title: "nft_collection.overview.links".localized)
                    ]
            ),
            Section(
                    id: "links",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin24),
                    rows: viewItems.enumerated().map { index, link in
                        linkRow(
                                iconImage: linkIcon(type: link.type),
                                title: linkTitle(type: link.type),
                                url: link.url,
                                isFirst: index == 0,
                                isLast: index == viewItems.count - 1
                        )
                    }
            )
        ]
    }

    private func linkRow(iconImage: UIImage?, title: String, url: String, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: tableView,
                id: "link-\(title)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = iconImage?.withTintColor(.themeGray)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_small_forward_20")?.withTintColor(.themeGray)
                    }
                },
                action: { [weak self] in
                    self?.openLink(url: url)
                }
        )
    }

    private func poweredBySection(text: String) -> SectionProtocol {
        Section(
                id: "powered-by",
                headerState: .margin(height: .margin8),
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

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            let logoHeaderSection = Section(
                    id: "logo-header",
                    rows: [
                        logoHeaderRow(viewItem: viewItem)
                    ]
            )

            sections.append(logoHeaderSection)

            sections.append(contentsOf: chartSection(statCharts: viewItem.statCharts))

            if let description = viewItem.description {
                sections.append(descriptionSection(description: description))
            }

            if !viewItem.contracts.isEmpty {
                sections.append(contractsSection(viewItems: viewItem.contracts))
            }

            if !viewItem.links.isEmpty {
                sections.append(contentsOf: linksSections(viewItems: viewItem.links))
            }

            sections.append(poweredBySection(text: "Powered by OpenSea API"))
        }

        return sections
    }

}
