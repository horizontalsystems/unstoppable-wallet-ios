import UIKit
import ComponentKit
import SectionsTableView

class DonateDescriptionDataSource: NSObject, ISectionDataSource {
    weak var delegate: ISectionDataSourceDelegate?
    weak var viewController: UIViewController?

    private func showAddresses() {
        let viewController = DonateAddressModule.viewController
        self.viewController?.navigationController?.pushViewController(viewController, animated: true)
    }

    private let rootGetAddressElement: CellBuilderNew.CellElement = .hStack([
        .textElement(text: .body("donate.list.get_address".localized)),
        .margin8,
        .image20 { (component: ImageComponent) -> () in
            component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
        }
    ])

    func prepare(tableView: UITableView) {
        tableView.registerCell(forClass: DonateDescriptionCell.self)
        tableView.registerCell(forClass: BaseSelectableThemeCell.self)
        tableView.registerCell(forClass: EmptyCell.self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath

        switch indexPath.row {
        case 0: return tableView.dequeueReusableCell(withIdentifier: String(describing: DonateDescriptionCell.self), for: originalIndexPath)
        case 1: return tableView.dequeueReusableCell(withIdentifier: String(describing: EmptyCell.self), for: indexPath)
        default:
            return CellBuilderNew.preparedCell(
                    tableView: tableView,
                    indexPath: originalIndexPath,
                    selectable: true,
                    rootElement: rootGetAddressElement,
                    layoutMargins: UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
            )
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? DonateDescriptionCell {
            cell.label.text = "donate.support.description".localized
        }

        if let cell = cell as? BaseSelectableThemeCell {
            cell.set(backgroundStyle: .transparent, isLast: true)
            cell.bind(rootElement: rootGetAddressElement)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return DonateDescriptionCell.height(containerWidth: tableView.width, text: "donate.support.description".localized)
        case 1: return .margin12
        default: return .heightSingleLineCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            let originalIndexPath = delegate?.originalIndexPath(tableView: tableView, dataSource: self, indexPath: indexPath) ?? indexPath
            tableView.deselectRow(at: originalIndexPath, animated: true)
            showAddresses()
        }
    }

}
