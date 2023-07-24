import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import HUD
import ComponentKit

class MarketAdvancedSearchViewController: ThemeViewController {
    private let viewModel: MarketAdvancedSearchViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let coinListCell = BaseSelectableThemeCell()
    private let marketCapCell = BaseSelectableThemeCell()
    private let volumeCell = BaseSelectableThemeCell()
    private let blockchainsCell = BaseSelectableThemeCell()
    private let periodCell = BaseSelectableThemeCell()
    private let priceChangeCell = BaseSelectableThemeCell()

    private let outperformedBtcCell = BaseThemeCell()
    private let outperformedEthCell = BaseThemeCell()
    private let outperformedBnbCell = BaseThemeCell()
    private let priceCloseToAthCell = BaseThemeCell()
    private let priceCloseToAtlCell = BaseThemeCell()

    private let showResultButtonHolder = BottomGradientHolder()
    private let showResultButton = PrimaryButton()

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
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "market.advanced_search.reset_all".localized, style: .plain, target: self, action: #selector(onTapReset))

        coinListCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        marketCapCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        volumeCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        blockchainsCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        priceChangeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        periodCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)

        outperformedBtcCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        buildToggle(cell: outperformedBtcCell, title: "market.advanced_search.outperformed_btc".localized) { [weak self] in
            self?.onTapOutperformedBtcCell(isOn: $0)
        }

        outperformedEthCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        buildToggle(cell: outperformedEthCell, title: "market.advanced_search.outperformed_eth".localized) { [weak self] in
            self?.onTapOutperformedEthCell(isOn: $0)
        }

        outperformedBnbCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        buildToggle(cell: outperformedBnbCell, title: "market.advanced_search.outperformed_bnb".localized) { [weak self] in
            self?.onTapOutperformedBnbCell(isOn: $0)
        }

        priceCloseToAthCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        buildToggle(cell: priceCloseToAthCell, title: "market.advanced_search.price_close_to_ath".localized) { [weak self] in
            self?.onTapPriceCloseToAthCell(isOn: $0)
        }

        priceCloseToAtlCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        buildToggle(cell: priceCloseToAtlCell, title: "market.advanced_search.price_close_to_atl".localized) { [weak self] in
            self?.onTapPriceCloseToAtlCell(isOn: $0)
        }

        showResultButtonHolder.add(to: self, under: tableView)
        showResultButtonHolder.addSubview(showResultButton)

        showResultButton.set(style: .yellow)
        showResultButton.addTarget(self, action: #selector(onTapShowResult), for: .touchUpInside)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalTo(showResultButton)
        }

        tableView.buildSections()

        subscribe(disposeBag, viewModel.coinListViewItemDriver) { [weak self] in
            self?.syncCoinList(viewItem: $0)
        }
        subscribe(disposeBag, viewModel.marketCapViewItemDriver) { [weak self] in
            self?.syncMarketCap(viewItem: $0)
        }
        subscribe(disposeBag, viewModel.volumeViewItemDriver) { [weak self] in
            self?.syncVolume(viewItem: $0)
        }
        subscribe(disposeBag, viewModel.blockchainsViewItemDriver) { [weak self] in
            self?.syncBlockchains(viewItem: $0)
        }
        subscribe(disposeBag, viewModel.priceChangeTypeViewItemDriver) { [weak self] in
            self?.syncPeriod(viewItem: $0)
        }
        subscribe(disposeBag, viewModel.priceChangeViewItemDriver) { [weak self] in
            self?.syncPriceChange(viewItem: $0)
        }

        subscribe(disposeBag, viewModel.buttonStateDriver) { [weak self] in
            self?.sync(buttonState: $0)
        }
    }

    private func buildSelector(cell: BaseThemeCell, title: String? = nil, viewItem: MarketAdvancedSearchViewModel.ViewItem? = nil) {
        let elements = tableView.universalImage24Elements(
                title: .body(title),
                value: viewItem.map { .subhead1($0.value, color: $0.valueStyle.valueTextColor )},
                accessoryType: .dropdown)
        CellBuilderNew.buildStatic(cell: cell, rootElement: .hStack(elements)
        )
    }

    private func buildToggle(cell: BaseThemeCell, title: String? = nil, onToggle: @escaping (Bool) -> ()) {
        let elements = tableView.universalImage24Elements(
                title: .body(title),
                accessoryType: .switch(onSwitch: onToggle))
        CellBuilderNew.buildStatic(cell: cell, rootElement: .hStack(elements))
    }

    private func selectorItems(viewItems: [MarketAdvancedSearchViewModel.FilterViewItem]) -> [SelectorModule.ViewItem] {
        viewItems.map {
            SelectorModule.ViewItem(
                    title: $0.title,
                    titleColor: $0.style.filterTextColor,
                    selected: $0.selected
            )
        }
    }

    private func showSelector(image: UIImage?, title: String, viewItems: [SelectorModule.ViewItem], onSelect: @escaping (Int) -> ()) {
        let viewController = SelectorModule.bottomSingleSelectorViewController(
                image: .local(image: image),
                title: title,
                viewItems: viewItems,
                onSelect: onSelect
        )

        DispatchQueue.main.async {
            self.present(viewController, animated: true)
        }
    }

    private func onTapCoinListCell() {
        showSelector(
                image: UIImage(named: "circle_coin_24")?.withTintColor(.themeJacob),
                title: "market.advanced_search.choose_set".localized,
                viewItems: selectorItems(viewItems: viewModel.coinListViewItems)
        ) { [weak self] index in
            self?.viewModel.setCoinList(at: index)
        }
    }

    private func onTapMarketCapCell() {
        showSelector(
                image: UIImage(named: "usd_24")?.withTintColor(.themeJacob),
                title: "market.advanced_search.market_cap".localized,
                viewItems: selectorItems(viewItems: viewModel.marketCapViewItems)
        ) { [weak self] index in
            self?.viewModel.setMarketCap(at: index)
        }
    }

    private func onTapVolumeCell() {
        showSelector(
                image: UIImage(named: "chart_2_24")?.withTintColor(.themeJacob),
                title: "market.advanced_search.volume".localized,
                viewItems: selectorItems(viewItems: viewModel.volumeViewItems)
        ) { [weak self] index in
            self?.viewModel.setVolume(at: index)
        }
    }

    private func onTapBlockchainsCell() {
        let viewController = SelectorModule.multiSelectorViewController(
                title: "market.advanced_search.blockchains".localized,
                viewItems: viewModel.blockchainViewItems,
                onFinish: { [weak self] in
                    self?.viewModel.setBlockchains(indexes: $0)
                }
        )

        present(viewController, animated: true)
    }

    private func onTapPeriodCell() {
        showSelector(
                image: UIImage(named: "circle_clock_24")?.withTintColor(.themeJacob),
                title: "market.advanced_search.price_period".localized,
                viewItems: selectorItems(viewItems: viewModel.priceChangeTypeViewItems)
        ) { [weak self] index in
            self?.viewModel.setPriceChangeType(at: index)
        }
    }

    private func onTapPriceChangeCell() {
        showSelector(
                image: UIImage(named: "markets_24")?.withTintColor(.themeJacob),
                title: "market.advanced_search.price_change".localized,
                viewItems: selectorItems(viewItems: viewModel.priceChangeViewItems)
        ) { [weak self] index in
            self?.viewModel.setPriceChange(at: index)
        }
    }

    private func onTapOutperformedBtcCell(isOn: Bool) {
        viewModel.setOutperformedBtc(isOn: isOn)
    }

    private func onTapOutperformedEthCell(isOn: Bool) {
        viewModel.setOutperformedEth(isOn: isOn)
    }

    private func onTapOutperformedBnbCell(isOn: Bool) {
        viewModel.setOutperformedBnb(isOn: isOn)
    }

    private func onTapPriceCloseToAthCell(isOn: Bool) {
        viewModel.setPriceCloseToATH(isOn: isOn)
    }

    private func onTapPriceCloseToAtlCell(isOn: Bool) {
        viewModel.setPriceCloseToATL(isOn: isOn)
    }

    @objc private func onTapReset() {
        viewModel.reset()
    }

    @objc private func onTapShowResult() {
        let viewController = MarketAdvancedSearchResultModule.viewController(marketInfos: viewModel.marketInfos, priceChangeType: viewModel.priceChangeType)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func set(isOn: Bool, cell: BaseThemeCell) {
//        cell.bind(index: 1) { (component: SwitchComponent) in
//            component.switchView.isOn = isOn
//        }
    }

    private func syncCoinList(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        buildSelector(cell: coinListCell, title: "market.advanced_search.choose_set".localized, viewItem: viewItem)
    }

    private func syncMarketCap(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        buildSelector(cell: marketCapCell, title: "market.advanced_search.market_cap".localized, viewItem: viewItem)
    }

    private func syncVolume(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        buildSelector(cell: volumeCell, title: "market.advanced_search.volume".localized, viewItem: viewItem)
    }

    private func syncBlockchains(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        buildSelector(cell: blockchainsCell, title: "market.advanced_search.blockchains".localized, viewItem: viewItem)
    }

    private func syncPeriod(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        buildSelector(cell: periodCell, title: "market.advanced_search.price_period".localized, viewItem: viewItem)
    }

    private func syncPriceChange(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        buildSelector(cell: priceChangeCell, title: "market.advanced_search.price_change".localized, viewItem: viewItem)
    }

    private func sync(buttonState: MarketAdvancedSearchViewModel.ButtonState) {
        switch buttonState {
        case .loading:
            spinner.isHidden = false
            spinner.startAnimating()
            showResultButton.setTitle("", for: .normal)
            showResultButton.isEnabled = false
        case .emptyResults:
            spinner.isHidden = true
            showResultButton.setTitle("market.advanced_search.empty_results".localized, for: .normal)
            showResultButton.isEnabled = false
        case .showResults(let count):
            spinner.isHidden = true
            showResultButton.setTitle("\("market.advanced_search.show_results".localized): \(count)", for: .normal)
            showResultButton.isEnabled = true
        case .error(let description):
            spinner.isHidden = true
            showResultButton.setTitle(description, for: .normal)
            showResultButton.isEnabled = false
        }
    }

    private func row(cell: UITableViewCell, id: String, height: CGFloat = .heightCell48, action: (() -> ())? = nil) -> RowProtocol {
        StaticRow(
                cell: cell,
                id: id,
                height: height,
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
                footerState: .margin(height: .margin24),
                rows: [
                    row(cell: coinListCell, id: "coin_list") { [weak self] in
                        self?.onTapCoinListCell()
                    }
                ])
        )

        sections.append(Section(
                id: "market_filters",
                headerState: tableView.sectionHeader(text: "market.advanced_search.market_parameters".localized.uppercased()),
                footerState: .margin(height: .margin24),
                rows: [
                    row(cell: marketCapCell, id: "market_cap") { [weak self] in
                        self?.onTapMarketCapCell()
                    },
                    row(cell: volumeCell, id: "volume") { [weak self] in
                        self?.onTapVolumeCell()
                    }
                ])
        )

        sections.append(Section(
                id: "network_filters",
                headerState: tableView.sectionHeader(text: "market.advanced_search.network_parameters".localized.uppercased()),
                footerState: .margin(height: .margin24),
                rows: [
                    row(cell: blockchainsCell, id: "blockchains") { [weak self] in
                        self?.onTapBlockchainsCell()
                    }
                ])
        )

        sections.append(Section(
                id: "price_filters",
                headerState: tableView.sectionHeader(text: "market.advanced_search.price_parameters".localized.uppercased()),
                footerState: .margin(height: .margin32),
                rows: [
                    row(cell: priceChangeCell, id: "price_change") { [weak self] in
                        self?.onTapPriceChangeCell()
                    },
                    row(cell: periodCell, id: "price_period") { [weak self] in
                        self?.onTapPeriodCell()
                    },
                    row(cell: outperformedBtcCell, id: "outperformed_btc", height: .heightCell56),
                    row(cell: outperformedEthCell, id: "outperformed_eth", height: .heightCell56),
                    row(cell: outperformedBnbCell, id: "outperformed_bnb", height: .heightCell56),
                    row(cell: priceCloseToAthCell, id: "price_close_to_ath", height: .heightCell56),
                    row(cell: priceCloseToAtlCell, id: "price_close_to_atl", height: .heightCell56),
                ])
        )

        return sections
    }

}

extension MarketAdvancedSearchViewModel.ValueStyle {

    var valueTextColor: UIColor {
        switch self {
        case .none: return .themeGray
        case .positive: return .themeRemus
        case .negative: return .themeLucian
        case .normal: return .themeLeah
        }
    }

    var filterTextColor: UIColor {
        switch self {
        case .none: return .themeGray
        case .positive: return .themeRemus
        case .negative: return .themeLucian
        case .normal: return .themeLeah
        }
    }

}
