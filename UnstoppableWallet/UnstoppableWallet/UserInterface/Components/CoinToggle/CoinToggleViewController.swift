import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import MarketKit
import ComponentKit
import Alamofire

class CoinToggleViewController: ThemeSearchViewController {
    private let viewModel: ICoinToggleViewModel
    let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems: [CoinToggleViewModel.ViewItem] = []
    private var isLoaded = false

    init(viewModel: ICoinToggleViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(forClass: G4Cell.self)
        tableView.registerCell(forClass: G21Cell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.onUpdate(viewItems: $0) }

        tableView.buildSections()

        isLoaded = true
    }

    private func onUpdate(viewItems: [CoinToggleViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.fullCoin.coin } == viewItems.map { $0.fullCoin.coin }
        self.viewItems = viewItems

        if isLoaded {
            tableView.reload(animated: animated)
        }
    }

    private func rows(viewItems: [CoinToggleViewModel.ViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            let isLast = index == viewItems.count - 1

            switch viewItem.state {
            case let .toggleVisible(enabled, hasSettings):
                return Row<G21Cell>(
                        id: "coin_\(viewItem.fullCoin.coin.uid)",
                        hash: "coin_\(enabled)_\(hasSettings)_\(isLast)",
                        height: .heightDoubleLineCell,
                        bind: { [weak self] cell, _ in
                            cell.set(backgroundStyle: .claude, isLast: isLast)
                            //                        cell.titleImage = .image(coinType: viewItem.coin.type)
                            cell.title = viewItem.fullCoin.coin.name
                            cell.subtitle = viewItem.fullCoin.coin.code
                            //                        cell.rightBadgeText = viewItem.coin.type.blockchainType
                            cell.isOn = enabled
                            cell.onToggle = { [weak self] enabled in
                                self?.onToggle(viewItem: viewItem, enabled: enabled)
                            }
                            cell.rightButtonImage = hasSettings ? UIImage(named: "edit_20") : nil
                            cell.onTapRightButton = { [weak self] in
                                self?.viewModel.onTapSettings(fullCoin: viewItem.fullCoin)
                            }

                            cell.setTitleImage(urlString: viewItem.fullCoin.coin.imageUrl, placeholder: UIImage(named: viewItem.fullCoin.placeholderImageName))
                        }
                )
            case .toggleHidden:
                return Row<G4Cell>(
                        id: "coin_\(viewItem.fullCoin.coin.uid)",
                        hash: "coin_\(isLast)",
                        height: .heightDoubleLineCell,
                        autoDeselect: true,
                        bind: { cell, _ in
                            cell.set(backgroundStyle: .claude, isLast: isLast)

                            cell.title = viewItem.fullCoin.coin.name
                            cell.subtitle = viewItem.fullCoin.coin.code

                            cell.setTitleImage(urlString: viewItem.fullCoin.coin.imageUrl, placeholder: UIImage(named: viewItem.fullCoin.placeholderImageName))
                        },
                        action: { _ in
                            print("On click \(viewItem.fullCoin.coin.name)")
                        }
                )
            }
        }
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter ?? "")
    }

    private func onToggle(viewItem: CoinToggleViewModel.ViewItem, enabled: Bool) {
        if enabled {
            viewModel.onEnable(fullCoin: viewItem.fullCoin)
        } else {
            viewModel.onDisable(coin: viewItem.fullCoin.coin)
        }
    }

    func setToggle(on: Bool, coin: Coin) {
        guard let index = viewItems.firstIndex(where: { $0.fullCoin.coin == coin }) else {
            return
        }

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? G21Cell else {
            return
        }

        cell.set(isOn: on, animated: true)
    }

}

extension CoinToggleViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin4),
                    footerState: .margin(height: .margin32),
                    rows: rows(viewItems: viewItems)
            )
        ]
    }

}
