import UIKit
import ComponentKit

class DonateDescriptionDataSource: NSObject, ISectionDataSource {
    weak var delegate: ISectionDataSourceDelegate?

    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: DonateDescriptionCell.self)
        tableView.registerCell(forClass: EmptyCell.self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        switch indexPath.row {
        case 0: return tableView.dequeueReusableCell(withIdentifier: String(describing: DonateDescriptionCell.self), for: originalIndexPath)
        default: return tableView.dequeueReusableCell(withIdentifier: String(describing: EmptyCell.self), for: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? DonateDescriptionCell {
            cell.label.text = "donate.support.description".localized
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return DonateDescriptionCell.height(containerWidth: tableView.width, text: "donate.support.description".localized)
        default: return .margin12
        }
    }

}
