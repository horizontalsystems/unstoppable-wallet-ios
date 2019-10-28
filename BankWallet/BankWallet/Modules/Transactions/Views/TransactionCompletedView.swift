import UIKit
import SnapKit

class TransactionCompletedView: UIView {
    private var timeLabel = UILabel()
    private var completedImageView = UIImageView()

    init() {
        super.init(frame: .zero)

        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }
        completedImageView.image = UIImage(named: "Transaction Success Icon")
        addSubview(completedImageView)
        completedImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(timeLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.centerY.equalTo(timeLabel)
        }

        timeLabel.textColor = .appGray
        timeLabel.font = .appSubhead2
    }

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(status: TransactionStatus, date: Date) {
        guard status == .completed else {
            isHidden = true
            return
        }

        isHidden = false
        timeLabel.text = DateHelper.instance.formatTransactionTime(from: date)
    }

}
