import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class CoinToggleViewController: ThemeViewController {
    private let viewModel: ICoinToggleViewModel

    let disposeBag = DisposeBag()
    private var viewState: CoinToggleViewModel.ViewState = .empty

    private let tableView = SectionsTableView(style: .grouped)
    let searchController = UISearchController(searchResultsController: nil)

    private var currentFilter: String?

    init(viewModel: ICoinToggleViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(forClass: CoinToggleCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true

        navigationItem.searchController = searchController

        viewModel.viewStateDriver
                .drive(onNext: { [weak self] viewState in
                    self?.onUpdate(viewState: viewState)
                })
                .disposed(by: disposeBag)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .themeOz

            if let leftView = textField.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = .themeGray
            }
        }
    }

    private func onUpdate(viewState: CoinToggleViewModel.ViewState) {
        let animated = self.viewState.featuredViewItems.count == viewState.featuredViewItems.count && self.viewState.viewItems.count == viewState.viewItems.count
        self.viewState = viewState
        tableView.reload(animated: animated)
    }

    private func rows(viewItems: [CoinToggleViewModel.ViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            var action: ((CoinToggleCell) -> ())?

            if case .toggleHidden = viewItem.state {
                action = { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
            }

            return Row<CoinToggleCell>(
                    id: "coin_\(viewItem.coin.id)",
                    hash: "coin_\(viewItem.state)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                viewItem: viewItem,
                                last: index == viewItems.count - 1
                        ) { [weak self] enabled in
                            self?.onToggle(viewItem: viewItem, enabled: enabled)
                        }
                    },
                    action: action
            )
        }
    }

    func onSelect(viewItem: CoinToggleViewModel.ViewItem) {
    }

    private func onToggle(viewItem: CoinToggleViewModel.ViewItem, enabled: Bool) {
        if enabled {
            viewModel.onEnable(coin: viewItem.coin)
        } else {
            viewModel.onDisable(coin: viewItem.coin)
        }
    }

    func revert(coin: Coin) {
        revert(coin: coin, viewItems: viewState.featuredViewItems, section: 0)
        revert(coin: coin, viewItems: viewState.viewItems, section: 1)
    }

    private func revert(coin: Coin, viewItems: [CoinToggleViewModel.ViewItem], section: Int) {
        guard let index = viewItems.firstIndex(where: { $0.coin == coin }) else {
            return
        }

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: section)) as? CoinToggleCell else {
            return
        }

        cell.setToggleOff()
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

extension CoinToggleViewController: UISearchResultsUpdating {

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
