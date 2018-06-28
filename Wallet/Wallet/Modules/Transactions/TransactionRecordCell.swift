import UIKit

class TransactionRecordCell: UITableViewCell {

    @IBOutlet weak var label: UILabel?

    func bind(item: TransactionRecordViewItem) {
        label?.text = "\(item.transactionHash) --- \(item.incoming) --- \(item.blockHeight) --- \(item.amount.value) \(item.amount.coin.code) --- \(item.date)"
    }

}
