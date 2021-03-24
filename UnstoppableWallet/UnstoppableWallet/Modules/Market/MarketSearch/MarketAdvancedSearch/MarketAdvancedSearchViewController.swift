import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import CoinKit
import HUD

class MarketAdvancedSearchViewController: ThemeViewController {
    private let viewModel: MarketAdvancedSearchViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let coinListCell = B5Cell()
    private let marketCapCell = B5Cell()
    private let volumeCell = B5Cell()
    private let liquidityCell = B5Cell()
    private let periodCell = B5Cell()
    private let priceChangeCell = B5Cell()

    private let showResultButton = ThemeButton()
    private let spinner = HUDActivityView.create(with: .small20)

    init(viewModel: MarketAdvancedSearchViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market.advanced_search.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "market.advanced_search.reset_all".localized, style: .plain, target: self, action: #selector(onTapResetAll))

        coinListCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        coinListCell.title = "market.advanced_search.choose_set".localized
        coinListCell.valueActionEnabled = false

        marketCapCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        marketCapCell.title = "market.advanced_search.market_cap".localized
        marketCapCell.valueActionEnabled = false

        volumeCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        volumeCell.title = "market.advanced_search.volume".localized
        volumeCell.valueActionEnabled = false

        liquidityCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        liquidityCell.title = "market.advanced_search.liquidity".localized
        liquidityCell.valueActionEnabled = false

        priceChangeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        priceChangeCell.title = "market.advanced_search.price_change".localized
        priceChangeCell.valueActionEnabled = false

        periodCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        periodCell.title = "market.advanced_search.price_period".localized
        periodCell.valueActionEnabled = false

        view.addSubview(showResultButton)
        showResultButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        showResultButton.apply(style: .primaryYellow)
        showResultButton.addTarget(self, action: #selector(onTapShowResult), for: .touchUpInside)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalTo(showResultButton)
        }

        tableView.buildSections()

        subscribe(disposeBag, viewModel.coinListViewItemDriver) { [weak self] in self?.syncCoinList(viewItem: $0) }
        subscribe(disposeBag, viewModel.marketCapViewItemDriver) { [weak self] in self?.syncMarketCap(viewItem: $0) }
        subscribe(disposeBag, viewModel.volumeViewItemDriver) { [weak self] in self?.syncVolume(viewItem: $0) }
        subscribe(disposeBag, viewModel.liquidityViewItemDriver) { [weak self] in self?.syncLiquidity(viewItem: $0) }
        subscribe(disposeBag, viewModel.periodViewItemDriver) { [weak self] in self?.syncPeriod(viewItem: $0) }
        subscribe(disposeBag, viewModel.priceChangeViewItemDriver) { [weak self] in self?.syncPriceChange(viewItem: $0) }

        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.sync(error: $0) }
        subscribe(disposeBag, viewModel.showResultTitleDriver) { [weak self] in self?.sync(title: $0) }
        subscribe(disposeBag, viewModel.showResultEnabledDriver) { [weak self] in self?.sync(showResultEnabled: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] in self?.sync(loading: $0) }
    }

    private func selectorItems(viewItems: [MarketAdvancedSearchViewModel.FilterViewItem]) -> [ItemSelectorModule.Item] {
        viewItems.map {
            ItemSelectorModule.Item.complex(viewItem: ItemSelectorModule.ComplexViewItem(title: $0.title, titleColor: $0.color.color, selected: $0.selected))
        }
    }

    private func showAlert(titleViewItem: ItemSelectorModule.ComplexTitleViewItem, items: [ItemSelectorModule.Item], action: ((Int) -> ())?) {
        let alertController = ItemSelectorModule.viewController(title:
        .complex(viewItem: titleViewItem),
                items: items,
                onTap: { selector, index in
                    selector.dismiss(animated: true)

                    action?(index)
                })

        present(alertController.toBottomSheet, animated: true)
    }

    private func onTapCoinListCell() {
            let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.choose_set".localized,
                subtitle: "---------",
                image: UIImage(named: "circle_coin_24")?.tinted(with: .themeJacob))

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.coinListViewItems), action: { [weak self] index in
            self?.viewModel.setCoinList(at: index)
        })
    }

    private func onTapMarketCapCell() {
            let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.market_cap".localized,
                subtitle: "---------",
                image: UIImage(named: "usd_24")?.tinted(with: .themeJacob))

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.marketCapViewItems), action: { [weak self] index in
            self?.viewModel.setMarketCap(at: index)
        })
    }

    private func onTapVolumeCell() {
            let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.volume".localized,
                subtitle: "market.advanced_search.24h".localized,
                image: UIImage(named: "chart_2_24")?.tinted(with: .themeJacob))

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.volumeViewItems), action: { [weak self] index in
            self?.viewModel.setVolume(at: index)
        })
    }

    private func onTapLiquidityCell() {
            let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.liquidity".localized,
                subtitle: "market.advanced_search.24h".localized,
                image: UIImage(named: "circle_check_24")?.tinted(with: .themeJacob))

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.liquidityViewItems), action: { [weak self] index in
            self?.viewModel.setLiquidity(at: index)
        })
    }

    private func onTapPeriodCell() {
            let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.price_period".localized,
                subtitle: "---------",
                image: UIImage(named: "circle_clock_24")?.tinted(with: .themeJacob))

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.periodViewItems), action: { [weak self] index in
            self?.viewModel.setPeriod(at: index)
        })
    }

    private func onTapPriceChangeCell() {
            let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.price_change".localized,
                subtitle: "---------",
                image: UIImage(named: "markets_24")?.tinted(with: .themeJacob))

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.priceChangeViewItems), action: { [weak self] index in
            self?.viewModel.setPriceChange(at: index)
        })
    }

    @objc private func onTapResetAll() {
        viewModel.resetAll()
    }

    @objc private func onTapShowResult() {
        let viewController = MarketAdvancedSearchResultModule.viewController(service: viewModel.service)
        viewController.parentNavigationController = navigationController
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func set(viewItem: MarketAdvancedSearchViewModel.ViewItem?, cell: B5Cell) {
        guard let viewItem = viewItem else {
            cell.value = nil
            return
        }

        cell.value = viewItem.value
        cell.valueColor = viewItem.valueColor.color
    }

    private func syncCoinList(viewItem: MarketAdvancedSearchViewModel.ViewItem?) {
        set(viewItem: viewItem, cell: coinListCell)
    }

    private func syncMarketCap(viewItem: MarketAdvancedSearchViewModel.ViewItem?) {
        set(viewItem: viewItem, cell: marketCapCell)
    }

    private func syncVolume(viewItem: MarketAdvancedSearchViewModel.ViewItem?) {
        set(viewItem: viewItem, cell: volumeCell)
    }

    private func syncLiquidity(viewItem: MarketAdvancedSearchViewModel.ViewItem?) {
        set(viewItem: viewItem, cell: liquidityCell)
    }

    private func syncPeriod(viewItem: MarketAdvancedSearchViewModel.ViewItem?) {
        set(viewItem: viewItem, cell: periodCell)
    }

    private func syncPriceChange(viewItem: MarketAdvancedSearchViewModel.ViewItem?) {
        set(viewItem: viewItem, cell: priceChangeCell)
    }

    private func sync(error: String) {
        HudHelper.instance.showError(title: error)
    }

    private func sync(title: String?) {
        showResultButton.setTitle(title, for: .normal)
    }

    private func sync(showResultEnabled: Bool) {
        showResultButton.isEnabled = showResultEnabled
    }

    private func sync(loading: Bool) {
        if loading {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }
    }

    private func row(cell: UITableViewCell, id: String, action: (() -> ())?) -> RowProtocol {
        StaticRow(
                cell: cell,
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                action: action
        )
    }

}

extension MarketAdvancedSearchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "coin_list",
                headerState: .margin(height: .margin12),
                rows: [
                    row(cell: coinListCell, id: "coin_list") { [weak self] in self?.onTapCoinListCell() }
                ])
        )

        sections.append(Section(
                id: "market_filters",
                headerState: .margin(height: .margin32),
                rows: [
                    row(cell: marketCapCell, id: "market_cap") { [weak self] in self?.onTapMarketCapCell() },
                    row(cell: volumeCell, id: "volume") { [weak self] in self?.onTapVolumeCell() }
                ])
        )

//        let description = "market.advanced_search.dex_description".localized
//        let footerState: ViewState<BottomDescriptionHeaderFooterView> = .cellType(hash: "Dex_description", binder: { view in
//            view.bind(text: description)
//
//        }, dynamicHeight: { containerWidth in
//            BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: description)
//        })
//
//        sections.append(Section(
//                id: "liquidity",
//                headerState: .margin(height: .margin32),
//                footerState: footerState,
//                rows: [
//                    row(cell: liquidityCell, id: "liquidity") { [weak self] in self?.onTapLiquidityCell() }
//                ])
//        )

        sections.append(Section(
                id: "price_filters",
                headerState: .margin(height: .margin32),
                footerState: .margin(height: .margin32 + .heightButton),
                rows: [
                    row(cell: priceChangeCell, id: "price_change") { [weak self] in self?.onTapPriceChangeCell() },
                    row(cell: periodCell, id: "price_period") { [weak self] in self?.onTapPeriodCell() },
                ])
        )

        return sections
    }

}

extension MarketAdvancedSearchViewModel.ValueColor {

    var color: UIColor {
        switch self {
        case .none: return .themeGray
        case .positive: return .themeRemus
        case .negative: return .themeLucian
        case .normal: return .themeOz
        }
    }

}