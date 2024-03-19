import ComponentKit
import HUD
import RxSwift
import SnapKit
import ThemeKit
import UIKit

class TransactionsViewController: ThemeViewController {
    private let viewModel: TransactionsViewModel
    private let dataSource: TransactionsTableViewDataSource
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let typeFiltersView = FilterView(buttonStyle: .tab)
    private let syncSpinner = HUDActivityView.create(with: .medium24)

    private let filterBadge = UIView()

    init(viewModel: TransactionsViewModel, dataSource: TransactionsTableViewDataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource

        super.init()

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "filled_transaction_2n_24"), tag: 0)
        navigationItem.largeTitleDisplayMode = .never

        dataSource.viewController = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized

        let spinnerBarView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        spinnerBarView.addSubview(syncSpinner)

        let filterBarView = UIView()
        filterBarView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize32)
        }

        let filterButton = UIButton()
        filterBarView.addSubview(filterButton)
        filterButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGFloat.iconSize24)
        }

        filterButton.setImage(UIImage(named: "manage_2_24")?.withTintColor(.themeJacob), for: .normal)
        filterButton.setImage(UIImage(named: "manage_2_24")?.withTintColor(.themeYellow50), for: .highlighted)
        filterButton.addTarget(self, action: #selector(onTapFilter), for: .touchUpInside)

        filterBarView.addSubview(filterBadge)
        filterBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.size.equalTo(8)
        }

        filterBadge.cornerRadius = 4
        filterBadge.backgroundColor = .themeLucian

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: spinnerBarView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: filterBarView)

        view.addSubview(tableView)

        tableView.sectionHeaderTopPadding = 0
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.dataSource = dataSource
        tableView.delegate = dataSource

        view.addSubview(typeFiltersView)
        typeFiltersView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.height.equalTo(FilterView.height)
        }

        typeFiltersView.reload(filters: viewModel.typeFilterViewItems)

        typeFiltersView.onSelect = { [weak self] index in
            self?.viewModel.onSelectTypeFilter(index: index)
        }

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(typeFiltersView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.syncingDriver) { [weak self] in self?.sync(syncing: $0) }
        subscribe(disposeBag, viewModel.typeFilterIndexDriver) { [weak self] index in
            self?.typeFiltersView.select(index: index)
        }
        subscribe(disposeBag, viewModel.filterBadgeVisibleDriver) { [weak self] in self?.filterBadge.isHidden = !$0 }

        dataSource.prepare(tableView: tableView)
    }

    @objc private func onTapFilter() {
        let viewController = TransactionFilterModule.view(transactionsService: viewModel.service).toNavigationViewController()
        present(viewController, animated: true)
    }

    private func sync(syncing: Bool) {
        syncSpinner.isHidden = !syncing

        if syncing {
            syncSpinner.startAnimating()
        } else {
            syncSpinner.stopAnimating()
        }
    }
}
