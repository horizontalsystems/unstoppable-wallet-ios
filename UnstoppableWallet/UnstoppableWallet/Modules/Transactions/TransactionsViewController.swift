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
    private let dataSource: ISectionDataSource
    private let disposeBag = DisposeBag()

    private let headerView: TransactionsHeaderView
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = PlaceholderView()
    private let typeFiltersView = FilterView(buttonStyle: .tab)
    private let syncSpinner = HUDActivityView.create(with: .medium24)

    init(viewModel: TransactionsViewModel, dataSource: ISectionDataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource
        headerView = TransactionsHeaderView(viewModel: viewModel)

        super.init()

        headerView.viewController = self
        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "filled_transaction_2n_24"), tag: 0)
        navigationItem.largeTitleDisplayMode = .never
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

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.isHidden = true

        let holder = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        holder.addSubview(syncSpinner)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: holder)

        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.viewStatusDriver) { [weak self] in self?.sync(viewStatus: $0) }
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

    private func sync(viewStatus: TransactionsViewModel.ViewStatus) {
        syncSpinner.isHidden = !viewStatus.showProgress

        if viewStatus.showProgress {
            syncSpinner.startAnimating()
        } else {
            syncSpinner.stopAnimating()
        }

        if let messageType = viewStatus.messageType {
            switch messageType {
            case .syncing:
                emptyView.image = UIImage(named: "clock_48")
                emptyView.text = "transactions.syncing_text".localized
            case .empty:
                emptyView.image = UIImage(named: "outgoing_raw_48")
                emptyView.text = "transactions.empty_text".localized
            }

            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }
    }

}
