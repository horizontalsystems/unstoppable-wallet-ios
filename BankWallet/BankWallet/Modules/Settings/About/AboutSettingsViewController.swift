import UIKit
import SnapKit

class AboutSettingsViewController: WalletViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView()

    init() {
        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "settings_about.title".localized

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        tableView.register(UINib(nibName: String(describing: AboutCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AboutCell.self))

        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: AboutCell.self), for: indexPath)
    }

}
