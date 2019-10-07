import UIKit
import SectionsTableView

class ManageAccountsViewController: WalletViewController {
    private let delegate: IManageAccountsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [ManageAccountViewItem]()

    init(delegate: IManageAccountsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_manage_keys.title".localized

        tableView.registerCell(forClass: ManageAccountCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    @objc func doneDidTap() {
        delegate.didTapDone()
    }

    private var header: ViewState<TopDescriptionHeaderFooterView> {
        let descriptionText = "settings_manage_keys.description".localized

        return .cellType(
                hash: "top_description", 
                binder: { view in
                    view.bind(text: descriptionText)
                }, dynamicHeight: { [unowned self] _ in
                    TopDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: descriptionText)
                }
        )
    }

    private var rows: [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            Row<ManageAccountCell>(
                    id: "account_\(viewItem.title)",
                    dynamicHeight: { [unowned self] _ in
                        ManageAccountCell.height(containerWidth: self.tableView.bounds.width, viewItem: viewItem)
                    },
                    bind: { [unowned self] cell, _ in
                        cell.bind(viewItem: viewItem, onTapCreate: { [weak self] in
                            self?.delegate.didTapCreate(index: index)
                        }, onTapRestore: { [weak self] in
                            self?.delegate.didTapRestore(index: index)
                        }, onTapUnlink: { [weak self] in
                            self?.delegate.didTapUnlink(index: index)
                        }, onTapBackup: { [weak self] in
                            self?.delegate.didTapBackup(index: index)
                        })
                    }
            )
        }
    }

}

extension ManageAccountsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "wallets",
                    headerState: header,
                    rows: rows
            )
        ]
    }

}

extension ManageAccountsViewController: IManageAccountsView {

    func set(viewItems: [ManageAccountViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

    func showDoneButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .plain, target: self, action: #selector(doneDidTap))
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func showCreateConfirmation(title: String, coinCodes: String) {
        let controller = ManageAccountsCreateAccountViewController(title: "settings_manage_keys.add_wallet".localized, subtitle: title, coinCodes: coinCodes, onCreate: { [weak self] in
            self?.delegate.didConfirmCreate()
        })

        present(controller, animated: true)
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

    func showBackupRequired(predefinedAccountType: IPredefinedAccountType) {
        let controller = BackupRequiredViewController(subtitle: predefinedAccountType.title, text: "settings_manage_keys.delete.cant_delete".localized, onBackup: { [weak self] in
            self?.delegate.didRequestBackup()
        })

        present(controller, animated: true)
    }

}
