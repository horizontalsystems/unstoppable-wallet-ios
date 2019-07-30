import UIKit
import UIExtensions
import SnapKit

class RestoreViewController: WalletViewController {
    private let delegate: IRestoreViewDelegate

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = RestoreHeaderView()

    init(delegate: IRestoreViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))

        tableView.delegate = self
        tableView.dataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: RestoreAccountCell.self)

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func cancelDidTap() {
        delegate.didTapCancel()
    }

}

extension RestoreViewController: IRestoreView {
}

extension RestoreViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate.typesCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: RestoreAccountCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? RestoreAccountCell {
            cell.bind(predefinedAccountType: delegate.type(index: indexPath.row))
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        delegate.didSelect(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return RestoreAccountsTheme.rowHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RestoreHeaderView.height(containerWidth: tableView.bounds.width)
    }

}
