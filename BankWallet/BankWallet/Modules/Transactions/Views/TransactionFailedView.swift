import UIKit
import SnapKit
import RxSwift

class TransactionFailedView: UIView {
    private let failedImageView = UIImageView(image: UIImage(named: "Transaction Fail Icon")?.tinted(with: .appLucian))
    private let failedLabel = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(failedImageView)
        addSubview(failedLabel)

        failedImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalTo(self.failedLabel)
        }

        failedLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.failedImageView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.bottom.trailing.equalToSuperview()
        }

        failedLabel.font = .appSubhead2
        failedLabel.textColor = .appLucian
        failedLabel.text = "transactions.failed".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
