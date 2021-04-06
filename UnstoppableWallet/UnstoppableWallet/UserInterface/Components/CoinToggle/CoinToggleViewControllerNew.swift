import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import CoinKit

class CoinToggleViewControllerNew: ThemeSearchViewController {
    private let viewModel: ICoinToggleViewModelNew
    let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewState: CoinToggleViewModelNew.ViewState = .empty
    private var isLoaded = false

    init(viewModel: ICoinToggleViewModelNew) {
        self.viewModel = viewModel

        super.init(scrollView: tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(forClass: G21Cell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.viewStateDriver) { [weak self] in self?.onUpdate(viewState: $0) }

        tableView.buildSections()

        isLoaded = true
    }

    private func onUpdate(viewState: CoinToggleViewModelNew.ViewState) {
        let animated = isAnimated(viewItemsA: self.viewState.featuredViewItems, viewItemsB: viewState.featuredViewItems) && isAnimated(viewItemsA: self.viewState.viewItems, viewItemsB: viewState.viewItems)
        self.viewState = viewState

        if isLoaded {
            tableView.reload(animated: animated)
        }
    }

    private func isAnimated(viewItemsA: [CoinToggleViewModelNew.ViewItem], viewItemsB: [CoinToggleViewModelNew.ViewItem]) -> Bool {
        viewItemsA.count == viewItemsB.count
    }

    private func rows(viewItems: [CoinToggleViewModelNew.ViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            let isFirst = index == 0
            let isLast = index == viewItems.count - 1

            return Row<G21Cell>(
                    id: "coin_\(viewItem.coin.id)",
                    hash: "coin_\(viewItem.enabled)_\(isFirst)_\(isLast)",
                    height: .heightDoubleLineCell,
                    bind: { [weak self] cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                        cell.titleImage = .image(coinType: viewItem.coin.type)
                        cell.title = viewItem.coin.title
                        cell.subtitle = viewItem.coin.code
                        cell.rightBadgeText = viewItem.coin.type.blockchainType
                        cell.isOn = viewItem.enabled
                        cell.onToggle = { [weak self] enabled in
                            self?.onToggle(viewItem: viewItem, enabled: enabled)
                        }
                        cell.rightButtonImage = viewItem.hasSettings ? UIImage(named: "edit_20") : nil
                        cell.onTapRightButton = { [weak self] in
                            self?.viewModel.onTapSettings(coin: viewItem.coin)
                        }
                    }
            )
        }
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter)
    }

    private func onToggle(viewItem: CoinToggleViewModelNew.ViewItem, enabled: Bool) {
        if enabled {
            viewModel.onEnable(coin: viewItem.coin)
        } else {
            viewModel.onDisable(coin: viewItem.coin)
        }
    }

    func setToggle(on: Bool, coin: Coin) {
        setToggle(on: on, coin: coin, viewItems: viewState.featuredViewItems, section: 0)
        setToggle(on: on, coin: coin, viewItems: viewState.viewItems, section: 1)
    }

    private func setToggle(on: Bool, coin: Coin, viewItems: [CoinToggleViewModelNew.ViewItem], section: Int) {
        guard let index = viewItems.firstIndex(where: { $0.coin == coin }) else {
            return
        }

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: section)) as? G21Cell else {
            return
        }

        cell.set(isOn: on, animated: true)
    }

}

extension CoinToggleViewControllerNew: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "featured_coins",
                    headerState: .margin(height: .margin4),
                    footerState: .margin(height: viewState.featuredViewItems.isEmpty ? 0 : .margin32),
                    rows: rows(viewItems: viewState.featuredViewItems)
            ),
            Section(
                    id: "coins",
                    footerState: .margin(height: .margin32),
                    rows: rows(viewItems: viewState.viewItems)
            )
        ]
    }

}
