import UIKit
import UIExtensions
import SnapKit

class ManageWalletsViewController: WalletViewController {
    private let numberOfSections = 2
    private let walletsSection = 0
    private let coinsSection = 1

    private let delegate: IManageWalletsViewDelegate

    let tableView = UITableView(frame: .zero, style: .grouped)

    init(delegate: IManageWalletsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "settings_manage_wallet.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(done))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(forClass: ManageWalletCell.self)
        tableView.separatorColor = .clear
        tableView.setEditing(true, animated: false)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func close() {
        delegate.onClose()
    }

    @objc func done() {
        delegate.saveChanges()
    }

}

extension ManageWalletsViewController: IManageWalletsView {

    func updateUI() {
        tableView.reloadData()
    }

    func showNoAccount(coin: Coin) {
        let controller = ManageWalletsNoAccountViewController(coin: coin) { [weak self] in
            self?.delegate.didTapManageKeys()
        }
        present(controller, animated: true)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}

extension ManageWalletsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(in: section)
    }

    func numberOfRows(in section: Int) -> Int {
        if section == walletsSection {
            return delegate.walletsCount
        } else if section == coinsSection {
            return delegate.coinsCount
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: ManageWalletCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ManageWalletCell {
            let coin = indexPath.section == walletsSection ? delegate.wallet(forIndex: indexPath.row).coin : delegate.coin(forIndex: indexPath.row)
            cell.bind(coin: coin, first: indexPath.row == 0, last: numberOfRows(in: indexPath.section) == indexPath.row + 1)
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == walletsSection
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section != walletsSection {
            return IndexPath(row: tableView.numberOfRows(inSection: walletsSection) - 1, section: walletsSection)
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        delegate.moveWallet(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == walletsSection ? .delete : .insert
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate.disableWallet(atIndex: indexPath.row)
        } else if editingStyle == .insert {
            delegate.enableCoin(atIndex: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ManageWalletsTheme.rowHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var headerHeight: CGFloat = 0

        if section == walletsSection {
            if delegate.walletsCount > 0 {
                headerHeight = ManageWalletsTheme.topHeaderHeight
            } else {
                headerHeight = 0
            }
        }
        if section == coinsSection {
            if delegate.walletsCount > 0 {
                headerHeight = ManageWalletsTheme.headerHeight
            } else {
                headerHeight = ManageWalletsTheme.topHeaderHeight
            }
        }
        return headerHeight
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == coinsSection, delegate.coinsCount > 0 {
            return ManageWalletsTheme.footerHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "button.remove".localized
    }

}
