import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class NftAssetOverviewViewController: ThemeViewController {
    private let viewModel: NftAssetOverviewViewModel
    private var urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private var viewItem: NftAssetOverviewViewModel.ViewItem?

    private let tableView = SectionsTableView(style: .grouped)
    private let wrapperView = UIView()
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private let imageCell = NftAssetImageCell()
    private let descriptionTextCell = ReadMoreTextCell()

    weak var parentNavigationController: UINavigationController?

    private var loaded = false

    init(viewModel: NftAssetOverviewViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

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
        tableView.registerCell(forClass: NftAssetButtonCell.self)
        tableView.registerCell(forClass: TextCell.self)
        tableView.registerCell(forClass: BrandFooterCell.self)
        tableView.registerCell(forClass: TraitsCell.self)
        tableView.sectionDataSource = self

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
        subscribe(disposeBag, viewModel.openTraitSignal) { [weak self] in self?.openTrait(url: $0) }

        loaded = true
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func sync(viewItem: NftAssetOverviewViewModel.ViewItem?) {
        self.viewItem = viewItem
        wrapperView.isHidden = viewItem != nil

        if loaded {
            tableView.reload()
        } else {
            tableView.buildSections()
        }
    }

    private func openTrait(url: String) {
        urlManager.open(url: url, from: parentNavigationController ?? self)
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func openShare(text: String) {
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: [])
        (parentNavigationController ?? self).present(activityViewController, animated: true, completion: nil)
    }

    private func linkTitle(type: NftAssetOverviewViewModel.LinkType) -> String {
        switch type {
        case .website: return "nft_asset.links.website".localized
        case .provider(let title): return title
        case .discord: return "Discord"
        case .twitter: return "Twitter"
        }
    }

    private func linkIcon(type: NftAssetOverviewViewModel.LinkType) -> UIImage? {
        switch type {
        case .website: return UIImage(named: "globe_20")
        case .provider: return UIImage(named: "open_sea_20")
        case .discord: return UIImage(named: "discord_20")
        case .twitter: return UIImage(named: "twitter_20")
        }
    }

    private func saleTitle(type: NftAssetMetadata.SaleType) -> String {
        switch type {
        case .onSale: return "nft_asset.on_sale".localized
        case .onAuction: return "nft_asset.on_auction".localized
        }
    }

    private func salePriceTitle(type: NftAssetMetadata.SaleType) -> String {
        switch type {
        case .onSale: return "nft_asset.buy_now".localized
        case .onAuction: return "nft_asset.minimum_bid".localized
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

        urlManager.open(url: url, from: parentNavigationController ?? self)
    }

    private func openSend() {
       guard let viewController = SendNftModule.viewController(nftUid: viewModel.nftUid) else {
           return
       }

        parentNavigationController?.present(viewController, animated: true)
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

        (parentNavigationController ?? self).present(controller, animated: true)
    }

    private func handleShare() {
        if let providerUrl = providerUrl {
            openShare(text: providerUrl)
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

    private var providerUrl: String? {
        guard let viewItem = viewItem else {
            return nil
        }

        for link in viewItem.links {
            switch link.type {
            case .provider: return link.url
            default: ()
            }
        }

        return nil
    }

    @objc private func onSaveToPhotos(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            HudHelper.instance.show(banner: .saved)
        } else {
            HudHelper.instance.show(banner: .error(string: "nft_asset.save_to_photos.failed".localized))
        }
    }

    private func openCollection(providerUid: String) {
        if let module = NftCollectionModule.viewController(blockchainType: viewModel.blockchainType, providerCollectionUid: providerUid) {
            (parentNavigationController ?? navigationController)?.pushViewController(module, animated: true)
        }
    }

}

extension NftAssetOverviewViewController: SectionsDataSource {

    private func headerRow(title: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text],
                tableView: tableView,
                id: "header-\(title)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    }
                }
        )
    }

    private func imageSection(ratio: CGFloat) -> SectionProtocol {
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

    private func titleSection(assetName: String, collectionName: String, providerCollectionUid: String) -> SectionProtocol {
        Section(
                id: "title",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    Row<NftAssetTitleCell>(
                            id: "title",
                            dynamicHeight: { width in
                                NftAssetTitleCell.height(containerWidth: width, text: assetName)
                            },
                            bind: { cell, _ in
                                cell.text = assetName
                            }
                    ),
                    CellBuilder.selectableRow(
                            elements: [.text, .image20],
                            tableView: tableView,
                            id: "collection",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell in
                                cell.set(backgroundStyle: .transparent, isFirst: true)

                                cell.bind(index: 0) { (component: TextComponent) in
                                    component.font = .subhead1
                                    component.textColor = .themeJacob
                                    component.text = collectionName
                                }

                                cell.bind(index: 1) { (component: ImageComponent) in
                                    component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                                }
                            },
                            action: { [weak self] in
                                self?.openCollection(providerUid: providerCollectionUid)
                            }
                    )
                ]
        )
    }

    private func buttonsSection(sendVisible: Bool) -> SectionProtocol {
        Section(
                id: "buttons",
                footerState: .margin(height: .margin24),
                rows: [
                    Row<NftAssetButtonCell>(
                            id: "buttons",
                            height: .heightButton,
                            bind: { [weak self] cell, _ in
                                cell.bind(
                                        providerTitle: self?.viewModel.providerTitle,
                                        onTapSend: sendVisible ? { [weak self] in
                                            self?.openSend()
                                        } : nil,
                                        onTapProvider: {
                                            if let url = self?.providerUrl {
                                                self?.openLink(url: url)
                                            }
                                        },
                                        onTapMore: {
                                            self?.openOptionsMenu()
                                        }
                                )
                            }
                    )
                ]
        )
    }

    private func priceRow(title: String, viewItem: NftAssetOverviewViewModel.PriceViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .multiText],
                tableView: tableView,
                id: "price-\(title)",
                hash: "\(viewItem.coinValue)-\(viewItem.fiatValue)-\(isLast)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    }
                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.font = .body
                        component.title.textColor = .themeJacob
                        component.subtitle.font = .subhead2
                        component.subtitle.textColor = .themeGray

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

    private func statsSection(viewItem: NftAssetOverviewViewModel.ViewItem) -> SectionProtocol? {
        var rows = [(String, NftAssetOverviewViewModel.PriceViewItem)]()

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

    private func saleRow(title: String, untilDate: String) -> RowProtocol {
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
                        component.title.font = .body
                        component.title.textColor = .themeLeah
                        component.subtitle.font = .subhead2
                        component.subtitle.textColor = .themeGray

                        component.title.text = title
                        component.subtitle.text = untilDate
                    }
                }
        )
    }

    private func saleSection(viewItem: NftAssetOverviewViewModel.ViewItem) -> SectionProtocol? {
        guard let saleViewItem = viewItem.sale else {
            return nil
        }

        return Section(
                id: "sale",
                footerState: .margin(height: viewItem.bestOffer == nil ? .margin24 : .margin12),
                rows: [
                    saleRow(
                            title: saleTitle(type: saleViewItem.type),
                            untilDate: saleViewItem.untilDate
                    ),
                    priceRow(
                            title: salePriceTitle(type: saleViewItem.type),
                            viewItem: saleViewItem.price,
                            isFirst: false,
                            isLast: true
                    )
                ]
        )
    }

    private func bestOfferSection(viewItem: NftAssetOverviewViewModel.ViewItem) -> SectionProtocol? {
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

    private func traitSections(traits: [NftAssetOverviewViewModel.TraitViewItem]) -> [SectionProtocol] {
        var traits = traits
        var sortedTraits = [NftAssetOverviewViewModel.TraitViewItem]()

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
                                bind: { [weak self] cell, _ in
                                    cell.bind(viewItems: sortedTraits, onSelect: { index in
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
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
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
                        component.onTap = {
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
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.font = .subhead1
                        component.textColor = .themeGray
                        component.text = value
                        component.setContentHuggingPriority(.required, for: .horizontal)
                        component.lineBreakMode = .byTruncatingMiddle
                    }
                }
        )
    }

    private func detailsSections(viewItem: NftAssetOverviewViewModel.ViewItem) -> [SectionProtocol] {
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
                        component.font = .body
                        component.textColor = .themeLeah
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

    private func linksSections(links: [NftAssetOverviewViewModel.LinkViewItem]) -> [SectionProtocol] {
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
            if let nftImage = viewItem.nftImage {
                imageCell.bind(nftImage: nftImage)
                sections.append(imageSection(ratio: nftImage.ratio))
            }

            sections.append(titleSection(assetName: viewItem.name, collectionName: viewItem.collectionName, providerCollectionUid: viewItem.providerCollectionUid))
            sections.append(buttonsSection(sendVisible: viewItem.sendVisible))

            if let section = statsSection(viewItem: viewItem) {
                sections.append(section)
            }

            if let section = saleSection(viewItem: viewItem) {
                sections.append(section)
            }

            if let section = bestOfferSection(viewItem: viewItem) {
                sections.append(section)
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
