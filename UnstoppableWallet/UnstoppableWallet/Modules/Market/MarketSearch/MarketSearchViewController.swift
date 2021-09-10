import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import ComponentKit
import Alamofire
import AlamofireImage

class MarketSearchViewController: ThemeSearchViewController {
    private let viewModel: MarketSearchViewModel
    private let disposeBag = DisposeBag()

    private let emptyLabel = UILabel()
    private let tableView = SectionsTableView(style: .grouped)
    private let advancedSearchCell = A1Cell()

    private var viewItems = [MarketSearchViewModel.ViewItem]()
    private var showAdvancedSearch: Bool = true

    private var isLoaded = false

    init(viewModel: MarketSearchViewModel) {
        self.viewModel = viewModel

        super.init(scrollView: tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "market.search.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: G4Cell.self)
        tableView.registerCell(forClass: A1Cell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive

        advancedSearchCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        advancedSearchCell.titleImage = UIImage(named: "sort_6_20")?.withRenderingMode(.alwaysTemplate)
        advancedSearchCell.titleImageTintColor = .themeGray
        advancedSearchCell.title = "market.advanced_search.title".localized

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
        }

        emptyLabel.text = "market.search.empty_text".localized
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .subhead2
        emptyLabel.textColor = .themeGray
        emptyLabel.textAlignment = .center

        Driver.zip(viewModel.viewItemsDriver, viewModel.showAdvancedSearchDriver)
                .drive(onNext: { [weak self] in self?.sync(viewItems: $0, showAdvancedSearch: $1) })
                .disposed(by: disposeBag)

        subscribe(disposeBag, viewModel.emptyResultDriver) { [weak self] in self?.sync(emptyResults: $0) }

        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationItem.searchController?.isActive = true
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    func onTapAdvancedSearch() {
        navigationController?.pushViewController(MarketAdvancedSearchModule.viewController(), animated: true)
    }

    private func onSelect(viewItem: MarketSearchViewModel.ViewItem) {
//        let viewController = CoinPageModule.viewController(launchMode: .partial(coinCode: viewItem.coinCode, coinTitle: viewItem.coinTitle, coinType: viewItem.coinType))
//        present(viewController, animated: true)
    }

    private func sync(viewItems: [MarketSearchViewModel.ViewItem], showAdvancedSearch: Bool) {
        self.viewItems = viewItems
        self.showAdvancedSearch = showAdvancedSearch

        reloadTable()
    }

    private func sync(emptyResults: Bool) {
        emptyLabel.isHidden = !emptyResults
    }

    override func onUpdate(filter: String?) {
        viewModel.apply(filter: filter)
    }

    private var advancedSearchRow: RowProtocol {
        StaticRow(
                cell: advancedSearchCell,
                id: "advanced_search",
                height: .heightCell48,
                autoDeselect: true,
                action: { [weak self] in
                    self?.onTapAdvancedSearch()
                }
        )
    }

    private var viewItemRows: [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            let isLast = index == viewItems.count - 1

            return Row<G4Cell>(
                    id: "coin_\(viewItem.coinName)_\(viewItem.coinCode)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .transparent, isLast: isLast)

                        cell.title = viewItem.coinName
                        cell.subtitle = viewItem.coinCode

                        cell.titleImage = nil

                        AF.request(viewItem.coinIconUrlString).responseImage { response in
                            if case .success(let image) = response.result {
                                cell.titleImage = image
                            }
                        }
                    },
                    action: { [weak self] _ in
                        self?.onSelect(viewItem: viewItem)
                    }
            )
        }
    }

    private func reloadTable() {
        tableView.buildSections()

        guard isLoaded else {
            return
        }

        tableView.reload()
    }

}

extension MarketSearchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if showAdvancedSearch {
            sections.append(
                    Section(
                            id: "advanced_search",
                            headerState: .margin(height: .margin12),
                            rows: [advancedSearchRow]
                    )
            )
        }

        let resultRows = viewItemRows
        if !resultRows.isEmpty {
            sections.append(
                    Section(
                            id: "coins",
                            headerState: sections.isEmpty ? .margin(height: .margin12) : .margin(height: .margin32),
                            footerState: .margin(height: .margin32),
                            rows: resultRows
                    ))
        }

        return sections
    }

}
