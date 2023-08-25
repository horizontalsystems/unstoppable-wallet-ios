import Combine
import UIKit
import ComponentKit
import MarketKit
import ThemeKit

class WalletTokenViewController: ThemeViewController {
    private let viewModel: WalletTokenViewModel
    private var cancellables = [AnyCancellable]()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let dataSource: ISectionDataSource

    init(viewModel: WalletTokenViewModel, dataSource: ISectionDataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource

        super.init()

        navigationItem.largeTitleDisplayMode = .never
        hidesBottomBarWhenPushed = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title.localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.delaysContentTouches = false

        tableView.dataSource = dataSource
        tableView.delegate = dataSource

        dataSource.prepare(tableView: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

}
