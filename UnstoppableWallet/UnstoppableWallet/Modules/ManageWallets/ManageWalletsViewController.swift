import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewController: ThemeViewController {
    private let viewModel: ManageWalletsViewModel

    private let disposeBag = DisposeBag()
    private var viewState: ManageWalletsModule.ViewState = .empty

    private let tableView = SectionsTableView(style: .grouped)
    private let searchController = UISearchController(searchResultsController: nil)

    private var currentFilter: String?

    init(viewModel: ManageWalletsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_coins.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "manage_coins.add_token".localized, style: .plain, target: self, action: #selector(onTapAddTokenButton))

        tableView.registerCell(forClass: CoinToggleCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        searchController.searchBar.placeholder = "manage_coins.search".localized
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true

        viewModel.viewStateDriver
                .drive(onNext: { [weak self] viewState in
                    self?.onUpdate(viewState: viewState)
                })
                .disposed(by: disposeBag)

        viewModel.openDerivationSettingsSignal
                .emit(onNext: { [weak self] coin, currentDerivation in
                    self?.showDerivationSettings(coin: coin, currentDerivation: currentDerivation)
                })
                .disposed(by: disposeBag)
    }

    @objc func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc func onTapAddTokenButton() {
        let module = AddTokenRouter.module(sourceViewController: self)
        present(module, animated: true)
    }

    private func onUpdate(viewState: ManageWalletsModule.ViewState) {
        let animated = self.viewState.featuredViewItems.count == viewState.featuredViewItems.count && self.viewState.viewItems.count == viewState.viewItems.count
        self.viewState = viewState
        tableView.reload(animated: animated)
    }

    private func rows(viewItems: [CoinToggleViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            var action: ((CoinToggleCell) -> ())?

            if case .toggleHidden = viewItem.state {
                action = { [weak self] _ in
                    self?.showNoAccount(viewItem: viewItem)
                }
            }

            return Row<CoinToggleCell>(
                    id: "coin_\(viewItem.coin.id)",
                    hash: "coin_\(viewItem.state)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                coin: viewItem.coin,
                                state: viewItem.state,
                                last: index == viewItems.count - 1
                        ) { [weak self] enabled in
                            self?.onToggle(viewItem: viewItem, enabled: enabled)
                        }
                    },
                    action: action
            )
        }
    }

    private func onToggle(viewItem: CoinToggleViewItem, enabled: Bool) {
        if enabled {
            viewModel.onEnable(coin: viewItem.coin)
        } else {
            viewModel.onDisable(coin: viewItem.coin)
        }
    }

    private func showNoAccount(viewItem: CoinToggleViewItem) {
        let module = NoAccountRouter.module(coin: viewItem.coin, sourceViewController: self)
        present(module, animated: true)
    }

    private func showDerivationSettings(coin: Coin, currentDerivation: MnemonicDerivation) {
        let module = DerivationSettingRouter.module(coin: coin, currentDerivation: currentDerivation, delegate: self)
        present(module, animated: true)
    }

    private func revert(coin: Coin, viewItems: [CoinToggleViewItem], section: Int) {
        guard let index = viewItems.firstIndex(where: { $0.coin == coin }) else {
            return
        }

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: section)) as? CoinToggleCell else {
            return
        }

        cell.setToggleOff()
    }

}

extension ManageWalletsViewController: SectionsDataSource {

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

extension ManageWalletsViewController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        var filter = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces)

        if filter == "" {
            filter = nil
        }

        if filter != currentFilter {
            currentFilter = filter
            viewModel.onUpdate(filter: filter)
        }
    }

}

extension ManageWalletsViewController: IDerivationSettingDelegate {

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        viewModel.onSelect(derivationSetting: derivationSetting, coin: coin)
    }

    func onCancelSelectDerivation(coin: Coin) {
        revert(coin: coin, viewItems: viewState.featuredViewItems, section: 0)
        revert(coin: coin, viewItems: viewState.viewItems, section: 1)
    }

}
