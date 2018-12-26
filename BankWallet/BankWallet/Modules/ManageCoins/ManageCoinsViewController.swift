import UIKit
import GrouviExtensions
import SnapKit

class ManageCoinsViewController: UITableViewController {
    let numberOfSections = 2
    let enabledSection = 0
    let disabledSection = 1

    let delegate: IManageCoinsViewDelegate

    init(delegate: IManageCoinsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(forClass: ManageCoinCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorColor = ManageCoinsTheme.separatorColor
        tableView.setEditing(true, animated: false)

        title = "settings_manage_wallet.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "alert.cancel".localized, style: .plain, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "restore.done".localized, style: .done, target: self, action: #selector(done))
        tableView.backgroundColor = AppTheme.controllerBackground

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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

extension ManageCoinsViewController {

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == enabledSection {
            return delegate.enabledCoinsCount
        } else if section == disabledSection {
            return delegate.disabledCoinsCount
        }
        return 0
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: ManageCoinCell.self), for: indexPath)
    }

    override public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ManageCoinCell {
            let coin = indexPath.section == enabledSection ? delegate.enabledItem(forIndex: indexPath.row) : delegate.disabledItem(forIndex: indexPath.row)
            cell.bind(coin: coin)
        }
    }

    override public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == enabledSection
    }

    override public func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section != enabledSection {
            return IndexPath(row: tableView.numberOfRows(inSection: enabledSection) - 1, section: enabledSection)
        }
        return proposedDestinationIndexPath
    }

    override public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        delegate.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == enabledSection ? .delete : .insert
    }

    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delegate.disable(atIndex: indexPath.row)
        } else if editingStyle == .insert {
            delegate.enable(atIndex: indexPath.row)
        }
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ManageCoinsTheme.rowHeight
    }

    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ManageCoinsTheme.headerHeight
    }

}
