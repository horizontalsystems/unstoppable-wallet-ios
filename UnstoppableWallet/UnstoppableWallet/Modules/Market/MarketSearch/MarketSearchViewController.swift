import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import CoinKit

class MarketSearchViewController: ThemeViewController {
    private let searchBar = UISearchBar()
    private var currentFilter: String?

    private let viewModel: MarketSearchViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [MarketSearchViewModel.ViewItem]()

    init(viewModel: MarketSearchViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market.search.title".localized
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: G4Cell.self)
        tableView.registerCell(forClass: A1Cell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        searchBar.showsCancelButton = false
        searchBar.placeholder = "placeholder.search".localized
        searchBar.delegate = self

        definesPresentationContext = true

        navigationItem.titleView = searchBar
        navigationItem.largeTitleDisplayMode = .never

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in
            self?.handle(viewItems: $0)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .themeOz

            if let leftView = textField.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = .themeGray
            }
        }
    }

    @objc func onTapClose() {
        navigationController?.popViewController(animated: true)
    }

    func onTapAdvancedSearch() {
        navigationController?.pushViewController(MarketAdvancedSearchModule.viewController(), animated: true)
    }

    private func onSelect(viewItem: MarketSearchViewModel.ViewItem) {
//        delegate?.didSelect(coin: coin)
        dismiss(animated: true)
    }

    private func handle(viewItems: [MarketSearchViewModel.ViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

    func onUpdate(filter: String?) {
        viewModel.apply(filter: filter)
    }

    private var advancedSearchRow: RowProtocol {
        Row<A1Cell>(
                id: "advanced_search",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.titleImage = UIImage(named: "sort_6_20")
                    cell.title = "market.search.advanced_search".localized
                }, action: { [weak self] cell in
                    self?.onTapAdvancedSearch()
                })
    }

    private var viewItemRows: [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            Row<G4Cell>(
                    id: "coin_\(viewItem.coinTitle)_\(viewItem.coinCode)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .transparent)

                        cell.title = viewItem.coinTitle
                        cell.subtitle = viewItem.coinCode
                        cell.leftBadgeText = viewItem.blockchainType
                        cell.titleImage = UIImage.image(coinCode: viewItem.coinCode, blockchainType: viewItem.blockchainType)
                    },
                    action: { [weak self] _ in
                        self?.onSelect(viewItem: viewItem)
                    }
            )
        }
    }

}

extension MarketSearchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let resultRows = viewItemRows
        if resultRows.isEmpty {
            return [
                Section(
                        id: "advanced_search",
                        headerState: .margin(height: .margin12),
                        rows: [advancedSearchRow]
                )
            ]
        }

        return [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: resultRows
            )
        ]
    }

}

extension MarketSearchViewController: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var filter: String? = searchText.trimmingCharacters(in: .whitespaces)

        if filter == "" {
            filter = nil
        }

        if filter != currentFilter {
            currentFilter = filter
            onUpdate(filter: filter)
        }
    }

}