import UIKit
import UIExtensions
import SnapKit

class ManageWalletsViewController: WalletViewController {
    private let numberOfSections = 2
    private let popularItemsSection = 0
    private let itemsSection = 1

    private let delegate: IManageWalletsViewDelegate

    let tableView = UITableView(frame: .zero, style: .grouped)

    init(delegate: IManageWalletsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_coins.title".localized

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(done))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(forClass: ManageWalletCell.self)
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    @objc func close() {
        delegate.close()
    }

    @objc func done() {
        delegate.saveChanges()
    }

}

extension ManageWalletsViewController: IManageWalletsView {

    func updateUI() {
        tableView.reloadData()
    }

    func showNoAccount(coin: Coin, predefinedAccountType: IPredefinedAccountType) {
        let controller = ManageWalletsNoAccountViewController(coin: coin, predefinedAccountType: predefinedAccountType, onSelectNew: { [weak self] in
            self?.delegate.didTapNew()
        }, onSelectRestore: { [weak self] in
            self?.delegate.didTapRestore()
        })

        controller.onDismiss = { [weak self] _ in
            self?.delegate.didCancelCreate()
        }

        present(controller, animated: true)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
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
        if section == popularItemsSection {
            return delegate.popularItemsCount
        } else if section == itemsSection {
            return delegate.itemsCount
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: ManageWalletCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ManageWalletCell else {
            return
        }

        let first = indexPath.row == 0
        let last = numberOfRows(in: indexPath.section) == indexPath.row + 1

        if indexPath.section == popularItemsSection {
            cell.bind(item: delegate.popularItem(index: indexPath.row), first: first, last: last) { [weak self] isOn in
                if isOn {
                    self?.delegate.enablePopularItem(index: indexPath.row)
                } else {
                    self?.delegate.disablePopularItem(index: indexPath.row)
                }
            }
        } else if indexPath.section == itemsSection {
            cell.bind(item: delegate.item(index: indexPath.row), first: first, last: last) { [weak self] isOn in
                if isOn {
                    self?.delegate.enableItem(index: indexPath.row)
                } else {
                    self?.delegate.disableItem(index: indexPath.row)
                }
            }
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
        if section == popularItemsSection {
            return ManageWalletsTheme.topHeaderHeight
        } else if section == itemsSection {
            return ManageWalletsTheme.headerHeight
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == itemsSection {
            return ManageWalletsTheme.footerHeight
        }
        return 0
    }

}
