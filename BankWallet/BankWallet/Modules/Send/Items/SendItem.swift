import UIKit

class SendItem {
    var itemClass: UITableViewCell.Type {
        fatalError("Must be implemented by successor.")
    }

    var bind: (() -> ())?
}
