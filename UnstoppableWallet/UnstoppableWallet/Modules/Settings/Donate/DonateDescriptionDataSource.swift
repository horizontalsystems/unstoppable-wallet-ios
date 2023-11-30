import ComponentKit
import SectionsTableView
import UIKit

class DonateDescriptionDataSource: NSObject, ISectionDataSource {
    weak var delegate: ISectionDataSourceDelegate?
    weak var viewController: UIViewController?

    private func showAddresses() {
        let viewController = DonateAddressModule.viewController
        self.viewController?.navigationController?.pushViewController(viewController, animated: true)
    }

    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: DonateDescriptionCell.self)
        tableView.registerCell(forClass: BorderedEmptyCell.self)
    }

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        switch indexPath.row {
        case 0: return tableView.dequeueReusableCell(withIdentifier: String(describing: DonateDescriptionCell.self), for: originalIndexPath)
        default: return tableView.dequeueReusableCell(withIdentifier: String(describing: BorderedEmptyCell.self), for: indexPath)
        }
    }

    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt _: IndexPath) {
        if let cell = cell as? DonateDescriptionCell {
            cell.label.text = "donate.support.description".localized
            cell.onGetAddressAction = { [weak self] in self?.showAddresses() }
        }
        if let cell = cell as? BorderedEmptyCell {
            cell.bottomBorder.isHidden = false
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return DonateDescriptionCell.height(containerWidth: tableView.width, text: "donate.support.description".localized)
        default: return .margin12
        }
    }
}
