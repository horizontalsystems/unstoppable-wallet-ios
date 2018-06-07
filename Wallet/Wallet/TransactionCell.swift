import UIKit

class TransactionCell: UITableViewCell {

    @IBOutlet weak var balanceChangeLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var confirmationsLabel: UILabel?
    @IBOutlet weak var receivedFromLabel: UILabel?
    @IBOutlet weak var transactionIdLabel: UILabel?
    @IBOutlet weak var miningFeeLabel: UILabel?
    @IBOutlet weak var blockLabel: UILabel?

    var formatter = DateFormatter()

    override func awakeFromNib() {
        super.awakeFromNib()

        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
    }

    func bind(transaction: TransactionData) {
        if transaction.result > 0 {
            balanceChangeLabel?.text = (transaction.outputs.first?.value).map { String(format: "+%.08f BTC", Double($0) / 100000000) }
            receivedFromLabel?.text = "Received From: \(transaction.inputs.first?.previousOutput.address ?? "?")"
        } else {
            balanceChangeLabel?.text = (transaction.outputs.first?.value).map { String(format: "-%.08f BTC", Double($0) / 100000000) }
            receivedFromLabel?.text = "Sent to: \(transaction.outputs.first?.address ?? "?")"
        }

        timeLabel?.text = formatter.string(from: Date(timeIntervalSince1970: Double(transaction.time)))
        confirmationsLabel?.text = "Confirmations: ?"
        transactionIdLabel?.text = "Transaction ID: \(transaction.hash)"
        miningFeeLabel?.text = "Mining Fee: \(String(format: "%.08f BTC", Double(transaction.fee) / 100000000))"
        blockLabel?.text = "Confirmed In Block: #\(transaction.blockHeight)"
    }

}
