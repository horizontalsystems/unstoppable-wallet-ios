import UIKit
import UIExtensions
import SnapKit
import SectionsTableView
import ThemeKit

class RestoreViewController: ThemeViewController {
    private let delegate: IRestoreViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var accountTypes = [AccountTypeViewItem]()

    init(delegate: IRestoreViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "button.back".localized, style: .plain, target: nil, action: nil)

        tableView.registerCell(forClass: RestoreAccountCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    private var walletRows: [RowProtocol] {
        accountTypes.enumerated().map { (index, accountType) in
            Row<RestoreAccountCell>(
                    id: "wallet_\(index)_row",
                    autoDeselect: true,
                    dynamicHeight: { [unowned self] _ in
                        RestoreAccountCell.height(containerWidth: self.tableView.bounds.width, accountType: accountType)
                    },
                    bind: { cell, _ in
                        cell.bind(accountType: accountType)
                    },
                    action: { [weak self] _ in
                        self?.delegate.didSelect(index: index)
                    }
            )
        }
    }

    private var header: ViewState<TopDescriptionHeaderFooterView> {
        let text = "restore.description".localized

        return .cellType(
                hash: "restore_footer",
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { [unowned self] _ in
                    return TopDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: text)
                }
        )
    }

}

extension RestoreViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "wallets",
                    headerState: header,
                    rows: walletRows
            )
        ]
    }

}

extension RestoreViewController: IRestoreView {

    func set(accountTypes: [AccountTypeViewItem]) {
        self.accountTypes = accountTypes

        tableView.reload()
    }

}
