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
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.textColor = .themeGray
        timeLabel.font = .subhead2

        addSubview(completedImageView)
        completedImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(timeLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview()
            maker.centerY.equalTo(timeLabel)
        }
        completedImageView.image = UIImage(named: "Transaction Success Icon")
        completedImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(date: Date) {
        timeLabel.text = DateHelper.instance.formatTransactionTime(from: date)
    }

}
