import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import CoinKit

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

    private var filters: [MarketAdvancedSearchViewModel.Filter: B5Cell]

    private let resetAllCell = B4Cell()
    private let showResultCell = ButtonCell()

    init(viewModel: MarketAdvancedSearchViewModel) {
        self.viewModel = viewModel
        filters = [
            .coinList: coinListCell,
            .marketCap: marketCapCell,
            .volume: volumeCell,
            .liquidity: liquidityCell,
            .period: periodCell,
            .priceChange: priceChangeCell,
        ]

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

        tableView.registerCell(forClass: B5Cell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.largeTitleDisplayMode = .always

        filters.forEach { (filter, cell) in
            cell.set(backgroundStyle: .lawrence, isFirst: filter.isFirst, isLast: filter.isLast)
            cell.title = filter.rawValue.localized
            cell.valueActionEnabled = false
        }

        resetAllCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        resetAllCell.title = "market.advanced_search.reset_all".localized
        resetAllCell.titleColor = .themeLucian
        resetAllCell.valueImage = UIImage(named: "trash_20")?.tinted(with: .themeGray)

        showResultCell.bind(style: .primaryYellow, title: "market.advanced_search.show_results".localized) { [weak self] in self?.onTapShowResult() }

        tableView.buildSections()

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.sync(error: $0) }
        subscribe(disposeBag, viewModel.itemCountDriver) { [weak self] in self?.sync(itemCount: $0) }
        subscribe(disposeBag, viewModel.showResultEnabledDriver) { [weak self] in self?.sync(showResultEnabled: $0) }
    }

    @objc private func onTapClose() {
        navigationController?.popViewController(animated: true)
    }

    private func onTapCell(filter: MarketAdvancedSearchViewModel.Filter) {
        let titleViewItem = ItemSelectorModule.ComplexTitleViewItem(
                title: filter.title,
                subtitle: filter.titleDescription,
                image: filter.titleImage?.tinted(with: .themeJacob))

        let viewItems = viewModel
                .viewItems(filter: filter)
                .map {
                    ItemSelectorModule.Item.complex(viewItem: ItemSelectorModule.ComplexViewItem(title: $0.title, titleColor: $0.color.color, selected: $0.selected))
                }

        let alertController = ItemSelectorModule.viewController(title:
                .complex(viewItem: titleViewItem),
                items: viewItems,
                onTap: { [weak self] selector, index in
                    self?.onTapViewItem(itemSelector: selector, filter: filter, index: index)
                })

        present(alertController.toBottomSheet, animated: true)
    }

    private func onTapResetAll() {
        viewModel.resetAll()
    }

    private func onTapShowResult() {
        let viewController = MarketAdvancedSearchResultModule.viewController(service: viewModel.service)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func onTapViewItem(itemSelector: ItemSelectorViewController, filter: MarketAdvancedSearchViewModel.Filter, index: Int) {
        itemSelector.dismiss(animated: true)

        viewModel.setField(at: index, filter: filter)
    }

    private func row(filter: MarketAdvancedSearchViewModel.Filter) -> RowProtocol {
        let cell = filters[filter] ?? B5Cell()
        return StaticRow(
                cell: cell,
                id: filter.rawValue,
                height: .heightCell48,
                autoDeselect: true,
                action: { [weak self] in self?.onTapCell(filter: filter) }
        )
    }

    private func sync(viewItems: [MarketAdvancedSearchViewModel.ViewItem]) {
        viewItems.forEach { viewItem in
            filters[viewItem.filter]?.value = viewItem.value
            filters[viewItem.filter]?.valueColor = viewItem.valueColor.color
        }
    }

    private func sync(error: String) {
        HudHelper.instance.showError(title: error)
    }

    private func sync(itemCount: Int?) {
        let itemCountString = itemCount.map { "\($0)" }
        showResultCell.title = ["market.advanced_search.show_results".localized, itemCountString].compactMap { $0 }.joined(separator: ": ")
    }

    private func sync(showResultEnabled: Bool) {
        showResultCell.isEnabled = showResultEnabled
    }

}

extension MarketAdvancedSearchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "coin_list",
                headerState: .margin(height: .margin12),
                rows: [
                    row(filter: .coinList)
                ])
        )

        sections.append(Section(
                id: "market_filters",
                headerState: .margin(height: .margin32),
                rows: [
                    row(filter: .marketCap),
                    row(filter: .volume),
                ])
        )

        let description = "market.advanced_search.dex_description".localized
        let footerState: ViewState<BottomDescriptionHeaderFooterView> = .cellType(hash: "Dex_description", binder: { view in
            view.bind(text: description)

        }, dynamicHeight: { containerWidth in
            BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: description)
        })

        sections.append(Section(
                id: "liquidity",
                headerState: .margin(height: .margin12),
                footerState: footerState,
                rows: [
                    row(filter: .liquidity),
                ])
        )

        sections.append(Section(
                id: "price_filters",
                headerState: .margin(height: .margin32),
                rows: [
                    row(filter: .period),
                    row(filter: .priceChange),
                ])
        )

        sections.append(Section(
                id: "reset_all",
                headerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                            cell: resetAllCell,
                            id: "reset_all",
                            height: .heightCell48,
                            autoDeselect: true,
                            action: { [weak self] in self?.onTapResetAll() }
                    )
                ])
        )

        sections.append(Section(
                id: "show_result",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin24),
                rows: [
                    StaticRow(
                            cell: showResultCell,
                            id: "show_result",
                            height: .heightCell48,
                            autoDeselect: true
                    )
                ])
        )

        return sections
    }

}

extension MarketAdvancedSearchViewModel.Filter {

    var titleImage: UIImage? {
        switch self {
        case .coinList: return UIImage(named: "circle_coin_24")
        case .marketCap: return UIImage(named: "usd_24")
        case .volume: return UIImage(named: "chart_2_24")
        case .liquidity: return UIImage(named: "circle_check_24")
        case .period: return UIImage(named: "circle_clock_24")
        case .priceChange: return UIImage(named: "markets_24")
        }
    }

    var titleDescription: String {
        switch self {
        case .volume, .liquidity: return "24h"
        default: return "---------"
        }
    }

    var isFirst: Bool {
        switch self {
        case .coinList, .marketCap, .liquidity, .period: return true
        default: return false
        }
    }

    var isLast: Bool {
        switch self {
        case .coinList, .volume, .liquidity, .priceChange: return true
        default: return false
        }
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