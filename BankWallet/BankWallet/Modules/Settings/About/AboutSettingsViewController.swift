import UIKit

class AboutSettingsViewController: UITableViewController {

    init() {
        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_about_title".localized

        tableView.register(UINib(nibName: String(describing: AboutCell.self), bundle: nil), forCellReuseIdentifier: String(describing: AboutCell.self))

        tableView.backgroundColor = App.shared.localStorage.lightMode ? UIColor.white : UIColor.cryptoDark
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: AboutCell.self), for: indexPath)
    }

}
