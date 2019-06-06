import UIKit
import UIExtensions
import SnapKit

class ManageCoinsViewController: WalletViewController {
    private let numberOfSections = 2
    private let enabledSection = 0
    private let disabledSection = 1

    private let delegate: IManageCoinsViewDelegate

    let tableView = UITableView(frame: .zero, style: .grouped)

    init(delegate: IManageCoinsViewDelegate) {
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
        tableView.registerCell(forClass: ManageCoinCell.self)
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

extension ManageCoinsViewController: IManageCoinsView {

    func updateUI() {
        tableView.reloadData()
    }

    func show(error: String) {
        HudHelper.instance.showError(title: error.localized)
    }

}

extension ManageCoinsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows(in: section)
    }

    func numberOfRows(in section: Int) -> Int {
        if section == enabledSection {
            return delegate.enabledCoinsCount
        } else if section == disabledSection {
            return delegate.disabledCoinsCount
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: ManageCoinCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ManageCoinCell {
            let coin = indexPath.section == enabledSection ? delegate.enabledItem(forIndex: indexPath.row) : delegate.disabledItem(forIndex: indexPath.row)
            cell.bind(coin: coin, first: indexPath.row == 0, last: numberOfRows(in: indexPath.section) == indexPath.row + 1)
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == enabledSection
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section != enabledSection {
            return IndexPath(row: tableView.numberOfRows(inSection: enabledSection) - 1, section: enabledSection)
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        delegate.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == enabledSection ? .delete : .insert
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate.disable(atIndex: indexPath.row)
        } else if editingStyle == .insert {
            delegate.enable(atIndex: indexPath.row)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ManageCoinsTheme.rowHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var headerHeight: CGFloat = 0

        if section == enabledSection {
            if delegate.enabledCoinsCount > 0 {
                headerHeight = ManageCoinsTheme.topHeaderHeight
            } else {
                headerHeight = 0
            }
        }
        if section == disabledSection {
            if delegate.enabledCoinsCount > 0 {
                headerHeight = ManageCoinsTheme.headerHeight
            } else {
                headerHeight = ManageCoinsTheme.topHeaderHeight
            }
        }
        return headerHeight
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == disabledSection, delegate.disabledCoinsCount > 0 {
            return ManageCoinsTheme.footerHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "button.remove".localized
    }

}
