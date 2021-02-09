import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class CoinToggleViewController: ThemeSearchViewController {
    private let viewModel: ICoinToggleViewModel

    let disposeBag = DisposeBag()
    private var viewState: CoinToggleViewModel.ViewState = .empty

    private let tableView = SectionsTableView(style: .grouped)

    private var isLoaded = false

    init(viewModel: ICoinToggleViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(forClass: G4Cell.self)
        tableView.registerCell(forClass: G11Cell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        viewModel.viewStateDriver
                .drive(onNext: { [weak self] viewState in
                    self?.onUpdate(viewState: viewState)
                })
                .disposed(by: disposeBag)

        tableView.buildSections()

        isLoaded = true
    }

    private func onUpdate(viewState: CoinToggleViewModel.ViewState) {
        let animated = isAnimated(viewItemsA: self.viewState.featuredViewItems, viewItemsB: viewState.featuredViewItems) && isAnimated(viewItemsA: self.viewState.viewItems, viewItemsB: viewState.viewItems)
        self.viewState = viewState

        if isLoaded {
            tableView.reload(animated: animated)
        }
    }

    private func isAnimated(viewItemsA: [CoinToggleViewModel.ViewItem], viewItemsB: [CoinToggleViewModel.ViewItem]) -> Bool {
        guard viewItemsA.count == viewItemsB.count else {
            return false
        }

        for (index, viewItemA) in viewItemsA.enumerated() {
            let viewItemB = viewItemsB[index]

            switch (viewItemA.state, viewItemB.state) {
            case (.toggleHidden, .toggleVisible), (.toggleVisible, .toggleHidden): return false
            default: ()
            }
        }

        return true
    }

    private func rows(viewItems: [CoinToggleViewModel.ViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            let isFirst = index == 0
            let isLast = index == viewItems.count - 1

            switch viewItem.state {
            case .toggleHidden:
                return Row<G4Cell>(
                        id: "coin_\(viewItem.coin.id)",
                        hash: "coin_\(viewItem.state)",
                        height: .heightDoubleLineCell,
                        autoDeselect: true,
                        bind: { cell, _ in
                            cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                            cell.titleImage = .image(coinCode: viewItem.coin.code, blockchainType: viewItem.coin.type.blockchainType)
                            cell.title = viewItem.coin.title
                            cell.subtitle = viewItem.coin.code
                            cell.leftBadgeText = viewItem.coin.type.blockchainType
                            cell.valueImage = UIImage(named: "plus_20")
                        },
                        action: { [weak self] _ in
                            self?.onSelect(viewItem: viewItem)
                        }
                )
            case .toggleVisible(let enabled):
                return Row<G11Cell>(
                        id: "coin_\(viewItem.coin.id)",
                        hash: "coin_\(viewItem.state)",
                        height: .heightDoubleLineCell,
                        bind: { [weak self] cell, _ in
                            cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                            cell.titleImage = .image(coinCode: viewItem.coin.code, blockchainType: viewItem.coin.type.blockchainType)
                            cell.title = viewItem.coin.title
                            cell.subtitle = viewItem.coin.code
                            cell.leftBadgeText = viewItem.coin.type.blockchainType
                            cell.isOn = enabled
                            cell.onToggle = { [weak self] enabled in
                                self?.onToggle(viewItem: viewItem, enabled: enabled)
                            }
                        }
                )
            }
        }
    }

    func onSelect(viewItem: CoinToggleViewModel.ViewItem) {
    }

      override func onUpdate(filter: String?) {
          viewModel.onUpdate(filter: filter)
      }

    private func onToggle(viewItem: CoinToggleViewModel.ViewItem, enabled: Bool) {
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

    private func setToggle(on: Bool, coin: Coin, viewItems: [CoinToggleViewModel.ViewItem], section: Int) {
        guard let index = viewItems.firstIndex(where: { $0.coin == coin }) else {
            return
        }

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: section)) as? G11Cell else {
            return
        }

        cell.set(isOn: on, animated: true)
    }

}

extension CoinToggleViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "featured_coins",
                    headerState: .margin(height: .margin1x),
                    footerState: .margin(height: viewState.featuredViewItems.isEmpty ? 0 : .margin8x),
                    rows: rows(viewItems: viewState.featuredViewItems)
            ),
            Section(
                    id: "coins",
                    footerState: .margin(height: .margin8x),
                    rows: rows(viewItems: viewState.viewItems)
            )
        ]
    }

}
