import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import UIKit

class NftCollectionOverviewViewController: ThemeViewController {
    private let viewModel: NftCollectionOverviewViewModel
    private var urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
    private let descriptionTextCell = ReadMoreTextCell()

    private var viewItem: NftCollectionOverviewViewModel.ViewItem?

    weak var parentNavigationController: UINavigationController?

    init(viewModel: NftCollectionOverviewViewModel, urlManager: UrlManager) {
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
        tableView.registerCell(forClass: LogoHeaderCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.registerCell(forClass: MarketCardCell.self)

        tableView.showsVerticalScrollIndicator = false

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in
            self?.sync(viewItem: $0)
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
        case let .provider(title): return title
        case .discord: return "Discord"
        case .twitter: return "Twitter"
        }
    }

    private func linkIcon(type: NftCollectionOverviewViewModel.LinkType) -> UIImage? {
        switch type {
        case .website: return UIImage(named: "globe_24")
        case .provider: return UIImage(named: "open_sea_24")
        case .discord: return UIImage(named: "discord_24")
        case .twitter: return UIImage(named: "twitter_24")
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

    private func chartSection(statCharts: NftCollectionOverviewViewModel.StatsViewItem) -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var marketCards = [MarketCardView.ViewItem]()
        marketCards.append(contentsOf:
            [
                statCharts.countItems,
                statCharts.floorPriceItems,
                statCharts.oneDayVolumeItems,
                statCharts.oneDaySalesItems,
            ].compactMap {
                $0
            }
        )

        guard !marketCards.isEmpty else {
            return sections
        }

        let chunks = marketCards.chunks(2)
        for (index, marketCards) in chunks.enumerated() {
            let isLast = index == chunks.count - 1
            sections.append(
                Section(
                    id: "chart_section_\(index)",
                    footerState: .margin(height: isLast ? .margin24 : .margin8),
                    rows: [
                        Row<MarketCardCell>(
                            id: "chart_row_\(index)",
                            height: MarketCardView.height,
                            bind: { cell, _ in
                                cell.clear()
                                for marketCard in marketCards {
                                    cell.append(viewItem: marketCard)
                                }
                            }
                        ),
                    ]
                )
            )
        }

        return sections
    }

    private func royaltySection(viewItem: NftCollectionOverviewViewModel.ViewItem) -> SectionProtocol? {
        let rowTexts = [
            viewItem.royalty.map { ("nft_collection.overview.royalty".localized, $0) },
            viewItem.inceptionDate.map { ("nft_collection.overview.inception_date".localized, $0) },
        ].compactMap { $0 }

        guard rowTexts.count > 0 else {
            return nil
        }

        return Section(
            id: "royalty",
            footerState: .margin(height: .margin24),
            rows: rowTexts.enumerated().map { index, tuple in
                tableView.universalRow48(
                    id: "text_\(index)",
                    title: .subhead2(tuple.0),
                    value: .subhead1(tuple.1),
                    isFirst: index == 0,
                    isLast: index == rowTexts.count - 1
                )
            }
        )
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
                tableView.headerInfoRow(id: "header_nft_collection.overview.description", title: "nft_collection.overview.description".localized),
                descriptionRow,
            ]
        )
    }

    private func contractsSection(viewItems: [NftCollectionOverviewViewModel.ContractViewItem]) -> SectionProtocol {
        Section(
            id: "contracts",
            headerState: .margin(height: .margin12),
            footerState: .margin(height: .margin24),
            rows: [
                tableView.headerInfoRow(id: "header.nft_collection.overview.contracts", title: "nft_collection.overview.contracts".localized),
            ] + viewItems.enumerated().map { index, viewItem in
                CellBuilderNew.row(
                    rootElement: .hStack([
                        .image32 { (component: ImageComponent) in
                            component.setImage(urlString: viewItem.iconUrl, placeholder: UIImage(named: "placeholder_rectangle_32"))
                        },
                        .vStackCentered([
                            .hStack([
                                .text { component in
                                    component.font = .body
                                    component.textColor = .themeLeah
                                    component.text = viewItem.name
                                    component.setContentHuggingPriority(.required, for: .horizontal)
                                },
                                .margin8,
                                .badge { component in
                                    component.isHidden = viewItem.schema == nil
                                    component.badgeView.set(style: .small)
                                    component.badgeView.text = viewItem.schema
                                },
                                .margin0,
                                .text { _ in },
                            ]),
                            .margin(1),
                            .text { component in
                                component.font = .subhead2
                                component.textColor = .themeGray
                                component.text = viewItem.reference.shortened
                            },
                        ]),
                        .secondaryCircleButton { (component: SecondaryCircleButtonComponent) in
                            component.button.set(image: UIImage(named: "copy_20"))
                            component.onTap = {
                                CopyHelper.copyAndNotify(value: viewItem.reference)
                            }
                        },
                        .secondaryCircleButton { (component: SecondaryCircleButtonComponent) in
                            if let explorerUrl = viewItem.explorerUrl {
                                component.isHidden = false
                                component.button.set(image: UIImage(named: "globe_20"))
                                component.onTap = { [weak self] in
                                    self?.urlManager.open(url: explorerUrl, from: self?.parentNavigationController)
                                }
                            } else {
                                component.isHidden = true
                            }
                        },
                    ]),
                    tableView: tableView,
                    id: "contract-\(index)",
                    height: .heightCell56,
                    bind: { cell in
                        cell.set(backgroundStyle: .lawrence, isFirst: index == 0, isLast: index == viewItems.count - 1)
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
                    tableView.headerInfoRow(id: "header.nft_collection.overview.links", title: "nft_collection.overview.links".localized),
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
            ),
        ]
    }

    private func linkRow(iconImage: UIImage?, title: String, url: String, isFirst: Bool, isLast: Bool) -> RowProtocol {
        tableView.universalRow48(
            id: "link-\(title)",
            image: .local(iconImage?.withTintColor(.themeGray)),
            title: .body(title),
            accessoryType: .disclosure,
            autoDeselect: true,
            isFirst: isFirst,
            isLast: isLast,
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
                ),
            ]
        )
    }

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem {
            let logoHeaderSection = Section(
                id: "logo-header",
                rows: [
                    logoHeaderRow(viewItem: viewItem),
                ]
            )

            sections.append(logoHeaderSection)

            sections.append(contentsOf: chartSection(statCharts: viewItem.statsViewItems))

            if let royaltySection = royaltySection(viewItem: viewItem) {
                sections.append(royaltySection)
            }

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
