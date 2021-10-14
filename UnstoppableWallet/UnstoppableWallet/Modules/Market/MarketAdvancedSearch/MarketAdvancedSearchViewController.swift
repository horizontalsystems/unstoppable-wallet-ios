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

    private let coinListCell = B5Cell()
    private let marketCapCell = B5Cell()
    private let volumeCell = B5Cell()
    private let periodCell = B5Cell()
    private let priceChangeCell = B5Cell()

    private let outperformedBtcCell = B11Cell()
    private let outperformedEthCell = B11Cell()
    private let outperformedBnbCell = B11Cell()
    private let priceCloseToAthCell = B11Cell()
    private let priceCloseToAtlCell = B11Cell()

    private let showResultButtonHolder = BottomGradientHolder()
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
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "market.advanced_search.reset_all".localized, style: .plain, target: self, action: #selector(onTapReset))

        coinListCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        coinListCell.title = "market.advanced_search.choose_set".localized

        marketCapCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        marketCapCell.title = "market.advanced_search.market_cap".localized

        volumeCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        volumeCell.title = "market.advanced_search.volume".localized

        priceChangeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        priceChangeCell.title = "market.advanced_search.price_change".localized

        periodCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        periodCell.title = "market.advanced_search.price_period".localized

        outperformedBtcCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        outperformedBtcCell.title = "market.advanced_search.outperformed_btc".localized
        outperformedBtcCell.onToggle = { [weak self] in self?.onTapOutperformedBtcCell(isOn: $0) }

        outperformedEthCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        outperformedEthCell.title = "market.advanced_search.outperformed_eth".localized
        outperformedEthCell.onToggle = { [weak self] in self?.onTapOutperformedEthCell(isOn: $0) }

        outperformedBnbCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        outperformedBnbCell.title = "market.advanced_search.outperformed_bnb".localized
        outperformedBnbCell.onToggle = { [weak self] in self?.onTapOutperformedBnbCell(isOn: $0) }

        priceCloseToAthCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: false)
        priceCloseToAthCell.title = "market.advanced_search.price_close_to_ath".localized
        priceCloseToAthCell.onToggle = { [weak self] in self?.onTapPriceCloseToATHCell(isOn: $0) }

        priceCloseToAtlCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        priceCloseToAtlCell.title = "market.advanced_search.price_close_to_atl".localized
        priceCloseToAtlCell.onToggle = { [weak self] in self?.onTapPriceCloseToATLCell(isOn: $0) }

        view.addSubview(showResultButtonHolder)
        showResultButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        showResultButtonHolder.addSubview(showResultButton)
        showResultButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
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
        subscribe(disposeBag, viewModel.periodViewItemDriver) { [weak self] in self?.syncPeriod(viewItem: $0) }
        subscribe(disposeBag, viewModel.priceChangeViewItemDriver) { [weak self] in self?.syncPriceChange(viewItem: $0) }

        subscribe(disposeBag, viewModel.outperformedBtcDriver) { [weak self] in self?.syncOutperformedBtc(isOn: $0) }
        subscribe(disposeBag, viewModel.outperformedEthDriver) { [weak self] in self?.syncOutperformedEth(isOn: $0) }
        subscribe(disposeBag, viewModel.outperformedBnbDriver) { [weak self] in self?.syncOutperformedBnb(isOn: $0) }
        subscribe(disposeBag, viewModel.priceCloseToATHDriver) { [weak self] in self?.syncPriceCloseToATH(isOn: $0) }
        subscribe(disposeBag, viewModel.priceCloseToATLDriver) { [weak self] in self?.syncPriceCloseToATL(isOn: $0) }

        subscribe(disposeBag, viewModel.buttonStateDriver) { [weak self] in self?.sync(buttonState: $0) }
    }

    private func selectorItems(viewItems: [MarketAdvancedSearchViewModel.FilterViewItem]) -> [ItemSelectorModule.Item] {
        viewItems.map {
            ItemSelectorModule.Item.complex(viewItem: ItemSelectorModule.ComplexViewItem(title: $0.title, titleColor: $0.color.color, selected: $0.selected))
        }
    }

    private func showAlert(titleViewItem: ItemSelectorModule.ComplexTitleViewItem, items: [ItemSelectorModule.Item], action: ((Int) -> ())?) {
        let alertController = ItemSelectorModule.viewController(title: .complex(viewItem: titleViewItem), items: items, onTap: { selector, index in
            selector.dismiss(animated: true)
            action?(index)
        })

        DispatchQueue.main.async {
            self.present(alertController.toBottomSheet, animated: true)
        }
    }

    private func onTapCoinListCell() {
        let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.choose_set".localized,
                subtitle: "---------",
                image: UIImage(named: "circle_coin_24"),
                tintColor: .themeJacob
        )

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.coinListViewItems), action: { [weak self] index in
            self?.viewModel.setCoinList(at: index)
        })
    }

    private func onTapMarketCapCell() {
        let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.market_cap".localized,
                subtitle: "---------",
                image: UIImage(named: "usd_24"),
                tintColor: .themeJacob
        )

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.marketCapViewItems), action: { [weak self] index in
            self?.viewModel.setMarketCap(at: index)
        })
    }

    private func onTapVolumeCell() {
        let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.volume".localized,
                subtitle: "market.advanced_search.24h".localized,
                image: UIImage(named: "chart_2_24"),
                tintColor: .themeJacob
        )

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.volumeViewItems), action: { [weak self] index in
            self?.viewModel.setVolume(at: index)
        })
    }

    private func onTapPeriodCell() {
        let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.price_period".localized,
                subtitle: "---------",
                image: UIImage(named: "circle_clock_24"),
                tintColor: .themeJacob
        )

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.periodViewItems), action: { [weak self] index in
            self?.viewModel.setPeriod(at: index)
        })
    }

    private func onTapPriceChangeCell() {
        let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: "market.advanced_search.price_change".localized,
                subtitle: "---------",
                image: UIImage(named: "markets_24"),
                tintColor: .themeJacob
        )

        showAlert(titleViewItem: titleViewItem, items: selectorItems(viewItems: viewModel.priceChangeViewItems), action: { [weak self] index in
            self?.viewModel.setPriceChange(at: index)
        })
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

    private func onTapPriceCloseToATHCell(isOn: Bool) {
        viewModel.setPriceCloseToATH(isOn: isOn)
    }

    private func onTapPriceCloseToATLCell(isOn: Bool) {
        viewModel.setPriceCloseToATL(isOn: isOn)
    }

    @objc private func onTapReset() {
        viewModel.reset()
    }

    @objc private func onTapShowResult() {
        let viewController = MarketAdvancedSearchResultModule.viewController(marketInfos: viewModel.marketInfos)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func set(viewItem: MarketAdvancedSearchViewModel.ViewItem, cell: B5Cell) {
        cell.value = viewItem.value
        cell.valueColor = viewItem.valueColor.color
    }

    private func syncCoinList(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        set(viewItem: viewItem, cell: coinListCell)
    }

    private func syncMarketCap(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        set(viewItem: viewItem, cell: marketCapCell)
    }

    private func syncVolume(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        set(viewItem: viewItem, cell: volumeCell)
    }

    private func syncPeriod(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        set(viewItem: viewItem, cell: periodCell)
    }

    private func syncPriceChange(viewItem: MarketAdvancedSearchViewModel.ViewItem) {
        set(viewItem: viewItem, cell: priceChangeCell)
    }

    private func syncOutperformedBtc(isOn: Bool) {
        outperformedBtcCell.isOn = isOn
    }

    private func syncOutperformedEth(isOn: Bool) {
        outperformedEthCell.isOn = isOn
    }

    private func syncOutperformedBnb(isOn: Bool) {
        outperformedBnbCell.isOn = isOn
    }

    private func syncPriceCloseToATH(isOn: Bool) {
        priceCloseToAthCell.isOn = isOn
    }

    private func syncPriceCloseToATL(isOn: Bool) {
        priceCloseToAtlCell.isOn = isOn
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

    private func row(cell: UITableViewCell, id: String, action: (() -> ())? = nil) -> RowProtocol {
        StaticRow(
                cell: cell,
                id: id,
                height: .heightCell48,
                autoDeselect: true,
                action: action
        )
    }

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

}

extension MarketAdvancedSearchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "coin_list",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    row(cell: coinListCell, id: "coin_list") { [weak self] in self?.onTapCoinListCell() }
                ])
        )

        sections.append(Section(
                id: "market_filters",
                headerState: header(text: "market.advanced_search.market_parameters".localized.uppercased()),
                footerState: .margin(height: .margin32),
                rows: [
                    row(cell: marketCapCell, id: "market_cap") { [weak self] in self?.onTapMarketCapCell() },
                    row(cell: volumeCell, id: "volume") { [weak self] in self?.onTapVolumeCell() }
                ])
        )

        sections.append(Section(
                id: "price_filters",
                headerState: header(text: "market.advanced_search.price_parameters".localized.uppercased()),
                footerState: .margin(height: .margin32),
                rows: [
                    row(cell: priceChangeCell, id: "price_change") { [weak self] in self?.onTapPriceChangeCell() },
                    row(cell: periodCell, id: "price_period") { [weak self] in self?.onTapPeriodCell() },
                    row(cell: outperformedBtcCell, id: "outperformed_btc"),
                    row(cell: outperformedEthCell, id: "outperformed_eth"),
                    row(cell: outperformedBnbCell, id: "outperformed_bnb"),
                    row(cell: priceCloseToAthCell, id: "price_close_to_ath"),
                    row(cell: priceCloseToAtlCell, id: "price_close_to_atl"),
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
