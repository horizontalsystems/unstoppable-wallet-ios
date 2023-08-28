import UIKit
import SnapKit
import ActionSheet
import ThemeKit
import HUD
import ComponentKit
import CurrencyKit
import RxSwift

class TransactionsViewController: ThemeViewController {
    private let viewModel: TransactionsViewModel
    private let dataSource: TransactionsTableViewDataSource
    private let disposeBag = DisposeBag()

    private let headerView: TransactionsHeaderView
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let typeFiltersView = FilterView(buttonStyle: .tab)
    private let syncSpinner = HUDActivityView.create(with: .medium24)

    init(viewModel: TransactionsViewModel, dataSource: TransactionsTableViewDataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource
        headerView = TransactionsHeaderView(viewModel: viewModel)

        super.init()

        headerView.viewController = self
        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "filled_transaction_2n_24"), tag: 0)
        navigationItem.largeTitleDisplayMode = .never

        dataSource.viewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.reset".localized, style: .plain, target: self, action: #selector(onTapReset))

        view.addSubview(tableView)

        tableView.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
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

        view.addSubview(headerView)
        headerView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(typeFiltersView.snp.bottom)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        let holder = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        holder.addSubview(syncSpinner)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: holder)

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.syncingDriver) { [weak self] in self?.sync(syncing: $0) }
        subscribe(disposeBag, viewModel.typeFilterIndexDriver) { [weak self] index in
            self?.typeFiltersView.select(index: index)
        }
        subscribe(disposeBag, viewModel.resetEnabledDriver) { [weak self] in
            self?.navigationItem.leftBarButtonItem?.isEnabled = $0
        }

        dataSource.prepare(tableView: tableView)
    }

    @objc private func onTapReset() {
        viewModel.onTapReset()
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
