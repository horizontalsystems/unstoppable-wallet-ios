import UIKit
import UIExtensions
import SnapKit

class ManageAccountsViewController: WalletViewController {
    private let descriptionSectionIndex = 0

    private let delegate: IManageAccountsViewDelegate

    private let tableView = UITableView(frame: .zero, style: .grouped)

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

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: ManageAccountCell.self)
        tableView.registerCell(forClass: ManageAccountDescriptionCell.self)

        delegate.viewDidLoad()
    }

    @objc func doneDidTap() {
        delegate.didTapDone()
    }

}

extension ManageAccountsViewController: IManageAccountsView {

    func showDoneButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .plain, target: self, action: #selector(doneDidTap))
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func reload() {
        tableView.reloadData()
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

extension ManageAccountsViewController: UITableViewDataSource, UITableViewDelegate {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == descriptionSectionIndex {
            return 1
        }
        return delegate.itemsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == descriptionSectionIndex {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: ManageAccountDescriptionCell.self), for: indexPath)
        }
        return tableView.dequeueReusableCell(withIdentifier: String(describing: ManageAccountCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ManageAccountCell else {
            return
        }

        let item = delegate.item(index: indexPath.row)
        cell.bind(viewItem: item, onTapCreate: { [weak self] in
            self?.delegate.didTapCreate(index: indexPath.row)
        }, onTapRestore: { [weak self] in
            self?.delegate.didTapRestore(index: indexPath.row)
        }, onTapUnlink: { [weak self] in
            self?.delegate.didTapUnlink(index: indexPath.row)
        }, onTapBackup: { [weak self] in
            self?.delegate.didTapBackup(index: indexPath.row)
        })
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == descriptionSectionIndex {
            return ManageAccountDescriptionCell.height(forContainerWidth: tableView.bounds.width)
        }
        return ManageAccountCell.height(containerWidth: tableView.bounds.width, viewItem: delegate.item(index: indexPath.row))
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

}
