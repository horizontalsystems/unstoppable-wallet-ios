import UIKit

extension UITableView {

    public func registerCell(forNib nibClass: UITableViewCell.Type) {
        register(UINib(nibName: String(describing: nibClass), bundle: Bundle(for: nibClass)), forCellReuseIdentifier: String(describing: nibClass))
    }

    public func registerCell(forClass anyClass: UITableViewCell.Type) {
        register(anyClass, forCellReuseIdentifier: String(describing: anyClass))
    }

    public func registerHeaderFooter(forNib nibClass: UITableViewHeaderFooterView.Type) {
        register(UINib(nibName: String(describing: nibClass), bundle: Bundle(for: nibClass)), forHeaderFooterViewReuseIdentifier: String(describing: nibClass))
    }

    public func registerHeaderFooter(forClass anyClass: UITableViewHeaderFooterView.Type) {
        register(anyClass, forHeaderFooterViewReuseIdentifier: String(describing: anyClass))
    }

}
