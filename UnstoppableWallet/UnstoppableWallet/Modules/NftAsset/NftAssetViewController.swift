import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView

class NftAssetViewController: ThemeViewController {
    private let viewModel: NftAssetViewModel
    private var urlManager: IUrlManager
    private var imageRatio: CGFloat
    private let disposeBag = DisposeBag()

    private var viewItem: NftAssetViewModel.ViewItem?
    private var statsViewItem: NftAssetViewModel.StatsViewItem?

    private let tableView = SectionsTableView(style: .grouped)
    private let imageCell = NftAssetImageCell()
    private let descriptionTextCell = ReadMoreTextCell()

    private var loaded = false

    init(viewModel: NftAssetViewModel, urlManager: IUrlManager, imageRatio: CGFloat) {
        self.viewModel = viewModel
        self.urlManager = urlManager
        self.imageRatio = imageRatio

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: NftAssetImageCell.self)
        tableView.registerCell(forClass: NftAssetTitleCell.self)
        tableView.registerCell(forClass: TextCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.registerCell(forClass: TraitsCell.self)
        tableView.sectionDataSource = self

        descriptionTextCell.set(backgroundStyle: .transparent, isFirst: true)
        descriptionTextCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.statsViewItemDriver) { [weak self] in self?.sync(statsViewItem: $0) }
        subscribe(disposeBag, viewModel.openTraitSignal) { [weak self] in self?.openTrait(url: $0) }

        loaded = true
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func sync(viewItem: NftAssetViewModel.ViewItem?) {
        self.viewItem = viewItem

        if loaded {
            tableView.reload(animated: true)
        } else {
            tableView.buildSections()
        }
    }

    private func sync(statsViewItem: NftAssetViewModel.StatsViewItem?) {
        self.statsViewItem = statsViewItem

        if loaded {
            tableView.reload(animated: true)
        } else {
            tableView.buildSections()
        }
    }

    private func openTrait(url: String) {
        urlManager.open(url: url, from: self)
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func openShare(text: String) {
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

    private func linkTitle(type: NftAssetViewModel.LinkType) -> String {
        switch type {
        case .website: return "nft_asset.links.website".localized
        case .openSea: return "OpenSea"
        case .discord: return "Discord"
        case .twitter: return "Twitter"
        }
    }

    private func linkIcon(type: NftAssetViewModel.LinkType) -> UIImage? {
        switch type {
        case .website: return UIImage(named: "globe_20")
        case .openSea: return UIImage(named: "open_sea_20")
        case .discord: return UIImage(named: "discord_20")
        case .twitter: return UIImage(named: "twitter_20")
        }
    }

    private func saleTitle(type: NftAssetService.SalePriceType) -> String {
        switch type {
        case .buyNow: return "nft_asset.buy_now".localized
        case .topBid: return "nft_asset.top_bid".localized
        case .minimumBid: return "nft_asset.minimum_bid".localized
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

        urlManager.open(url: url, from: self)
    }

    private func openOptionsMenu() {
        let controller = AlertViewControllerNew.instance(
                viewItems: [
                    .init(text: "button.share".localized),
                    .init(text: "nft_asset.options.save_to_photos".localized),
//                    .init(text: "nft_asset.options.set_as_watch_face".localized)
                ],
                reportAfterDismiss: true,
                onSelect: { [weak self] index in
                    switch index {
                    case 0: self?.handleShare()
                    case 1: self?.handleSaveToPhotos()
//                    case 2: self?.handleSetWatchFace()
                    default: ()
                    }
                }
        )

        present(controller, animated: true)
    }

    private func handleShare() {
        if let openSeaUrl = openSeaUrl {
            openShare(text: openSeaUrl)
        }
    }

    private func handleSaveToPhotos() {
        if let image = imageCell.currentImage {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(onSaveToPhotos), nil)
        }
    }

    private func handleSetWatchFace() {
        print("Set as Watch Face")
    }

    private var openSeaUrl: String? {
        viewItem?.links.first(where: { $0.type == .openSea })?.url
    }

    @objc private func onSaveToPhotos(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            HudHelper.instance.showSuccess(title: "nft_asset.save_to_photos.success".localized)
        } else {
            HudHelper.instance.showError(title: "nft_asset.save_to_photos.failed".localized)
        }
    }

}

extension NftAssetViewController: SectionsDataSource {

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

    private func imageSection(url: String, ratio: CGFloat) -> SectionProtocol {
        Section(
                id: "image",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: imageCell,
                            id: "image",
                            dynamicHeight: { width in
                                NftAssetImageCell.height(containerWidth: width, ratio: ratio)
                            }
                    )
                ]
        )
    }

    private func titleSection(title: String, subtitle: String) -> SectionProtocol {
        Section(
                id: "title",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin24),
                rows: [
                    Row<NftAssetTitleCell>(
                            id: "title",
                            dynamicHeight: { width in
                                NftAssetTitleCell.height(containerWidth: width, title: title, subtitle: subtitle)
                            },
                            bind: { cell, _ in
                                cell.bind(
                                        title: title,
                                        subtitle: subtitle,
                                        onTapOpenSea: { [weak self] in
                                            if let url = self?.openSeaUrl {
                                                self?.openLink(url: url)
                                            }
                                        },
                                        onTapMore: { [weak self] in
                                            self?.openOptionsMenu()
                                        }
                                )
                            }
                    )
                ]
        )
    }

    private func priceRow(title: String, viewItem: NftAssetViewModel.PriceViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .multiText],
                tableView: tableView,
                id: "price-\(title)",
                hash: "\(viewItem.coinValue)-\(viewItem.fiatValue)-\(isLast)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }
                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.set(style: .b3)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.coinValue
                        component.title.textAlignment = .right
                        component.title.setContentCompressionResistancePriority(.required, for: .horizontal)

                        component.subtitle.text = viewItem.fiatValue
                        component.subtitle.textAlignment = .right
                        component.subtitle.setContentCompressionResistancePriority(.required, for: .horizontal)
                    }
                }
        )
    }

    private func statsSection(viewItem: NftAssetViewModel.StatsViewItem) -> SectionProtocol? {
        var rows = [(String, NftAssetViewModel.PriceViewItem)]()

        if let priceViewItem = viewItem.lastSale {
            rows.append(("nft_asset.last_sale".localized, priceViewItem))
        }
        if let priceViewItem = viewItem.average7d {
            rows.append(("nft_asset.average_7d".localized, priceViewItem))
        }
        if let priceViewItem = viewItem.average30d {
            rows.append(("nft_asset.average_30d".localized, priceViewItem))
        }
        if let priceViewItem = viewItem.collectionFloor {
            rows.append(("nft_asset.floor_price".localized, priceViewItem))
        }

        guard !rows.isEmpty else {
            return nil
        }

        return Section(
                id: "stats",
                footerState: .margin(height: viewItem.sale == nil && viewItem.bestOffer == nil ? .margin24 : .margin12),
                rows: rows.enumerated().map { index, rowInfo in
                    priceRow(
                            title: rowInfo.0,
                            viewItem: rowInfo.1,
                            isFirst: index == 0,
                            isLast: index == rows.count - 1
                    )
                }
        )
    }

    private func saleRow(untilDate: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.multiText],
                tableView: tableView,
                id: "sale-until",
                hash: untilDate,
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true)

                    cell.bind(index: 0) { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = "nft_asset.on_sale".localized
                        component.subtitle.text = untilDate
                    }
                }
        )
    }

    private func saleSection(viewItem: NftAssetViewModel.StatsViewItem) -> SectionProtocol? {
        guard let saleViewItem = viewItem.sale else {
            return nil
        }

        return Section(
                id: "sale",
                footerState: .margin(height: viewItem.bestOffer == nil ? .margin24 : .margin12),
                rows: [
                    saleRow(untilDate: saleViewItem.untilDate),
                    priceRow(
                            title: saleTitle(type: saleViewItem.type),
                            viewItem: saleViewItem.price,
                            isFirst: false,
                            isLast: true
                    )
                ]
        )
    }

    private func bestOfferSection(viewItem: NftAssetViewModel.StatsViewItem) -> SectionProtocol? {
        guard let priceViewItem = viewItem.bestOffer else {
            return nil
        }

        return Section(
                id: "best-offer",
                footerState: .margin(height: .margin24),
                rows: [
                    priceRow(
                            title: "nft_asset.best_offer".localized,
                            viewItem: priceViewItem,
                            isFirst: true,
                            isLast: true
                    )
                ]
        )
    }

    private func traitSections(traits: [NftAssetViewModel.TraitViewItem]) -> [SectionProtocol] {
        var traits = traits
        var sortedTraits = [NftAssetViewModel.TraitViewItem]()

        let containerWidth = view.width - 2 * TraitsCell.horizontalInset
        var remainingWidth = containerWidth
        var lines = 0

        while !traits.isEmpty {
            let trait = traits.removeFirst()
            let traitSize = TraitCell.size(for: trait, containerWidth: containerWidth)

            sortedTraits.append(trait)
            remainingWidth -= traitSize.width + TraitsCell.interItemSpacing

            var remainingTraits = traits

            while !remainingTraits.isEmpty {
                let trait = remainingTraits.removeFirst()
                let traitSize = TraitCell.size(for: trait, containerWidth: containerWidth)

                if traitSize.width <= remainingWidth {
                    sortedTraits.append(trait)
                    traits.removeAll { $0.value == trait.value && $0.type == trait.type }
                    remainingWidth -= traitSize.width + TraitsCell.interItemSpacing
                }
            }

            remainingWidth = containerWidth
            lines += 1
        }

        return [
            Section(
                    id: "traits-header",
                    rows: [
                        headerRow(title: "nft_asset.properties".localized)
                    ]
            ),
            Section(
                    id: "traits",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin24),
                    rows: [
                        Row<TraitsCell>(
                                id: "traits",
                                height: TraitsCell.height(lines: lines),
                                bind: { cell, _ in
                                    cell.bind(viewItems: sortedTraits, onSelect: { [weak self] index in
                                        self?.viewModel.onSelectTrait(index: index)
                                    })
                                }
                        )
                    ]
            )
        ]
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
                    headerRow(title: "nft_asset.description".localized),
                    descriptionRow
                ]
        )
    }

    private func contractAddressRow(value: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .secondaryCircleButton, .secondaryCircleButton],
                tableView: tableView,
                id: "contract-address",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = "nft_asset.details.contract_address".localized
                    }
                    cell.bind(index: 1) { (component: SecondaryCircleButtonComponent) in
                        component.button.set(image: UIImage(named: "copy_20"))
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }
                    cell.bind(index: 2) { (component: SecondaryCircleButtonComponent) in
                        component.button.set(image: UIImage(named: "share_1_20"))
                        component.onTap = { [weak self] in
                            self?.openShare(text: value)
                        }
                    }
                }
        )
    }

    private func detailRow(title: String, value: String, isLast: Bool = false) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .text],
                tableView: tableView,
                id: "detail-\(title)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .c1)
                        component.text = value
                        component.setContentHuggingPriority(.required, for: .horizontal)
                        component.lineBreakMode = .byTruncatingMiddle
                    }
                }
        )
    }

    private func detailsSections(viewItem: NftAssetViewModel.ViewItem) -> [SectionProtocol] {
        [
            Section(
                    id: "details-header",
                    rows: [
                        headerRow(title: "nft_asset.details".localized)
                    ]
            ),
            Section(
                    id: "details",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin24),
                    rows: [
                        contractAddressRow(value: viewItem.contractAddress),
                        detailRow(title: "nft_asset.details.token_id".localized, value: viewItem.tokenId),
                        detailRow(title: "nft_asset.details.token_standard".localized, value: viewItem.schemaName),
                        detailRow(title: "nft_asset.details.blockchain".localized, value: viewItem.blockchain, isLast: true)
                    ]
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

    private func linksSections(links: [NftAssetViewModel.LinkViewItem]) -> [SectionProtocol] {
        [
            Section(
                    id: "links-header",
                    rows: [
                        headerRow(title: "nft_asset.links".localized)
                    ]
            ),
            Section(
                    id: "links",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin24),
                    rows: links.enumerated().map { index, link in
                        linkRow(
                                iconImage: linkIcon(type: link.type),
                                title: linkTitle(type: link.type),
                                url: link.url,
                                isFirst: index == 0,
                                isLast: index == links.count - 1
                        )
                    }
            )
        ]
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

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            if let imageUrl = viewItem.imageUrl {
                imageCell.bind(url: imageUrl)
                sections.append(imageSection(url: imageUrl, ratio: imageRatio))
            }

            sections.append(titleSection(title: viewItem.name, subtitle: viewItem.collectionName))

            if let statsViewItem = statsViewItem {
                if let section = statsSection(viewItem: statsViewItem) {
                    sections.append(section)
                }

                if let section = saleSection(viewItem: statsViewItem) {
                    sections.append(section)
                }

                if let section = bestOfferSection(viewItem: statsViewItem) {
                    sections.append(section)
                }
            }

            if !viewItem.traits.isEmpty {
                sections.append(contentsOf: traitSections(traits: viewItem.traits))
            }

            if let description = viewItem.description {
                sections.append(descriptionSection(description: description))
            }

            sections.append(contentsOf: detailsSections(viewItem: viewItem))

            if !viewItem.links.isEmpty {
                sections.append(contentsOf: linksSections(links: viewItem.links))
            }

            sections.append(poweredBySection(text: "Powered by OpenSea API"))
        }

        return sections
    }

}
