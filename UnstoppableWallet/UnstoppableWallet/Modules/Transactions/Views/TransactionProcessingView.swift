import UIKit
import SnapKit

class TransactionProcessingView: UIView {
    private let doubleSpendImageView = UIImageView()
    private let barsProgressView = BarsProgressView(color: .themeGray50, inactiveColor: .themeSteel20)
    private let processingLabel = UILabel()

    private var doubleSpendIconSizeConstraint: Constraint?
    private var doubleSpendIconRightMarginConstraint: Constraint?

    init() {
        super.init(frame: .zero)

        addSubview(barsProgressView)
        barsProgressView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        barsProgressView.set(barsCount: BarsProgressView.progressStepsCount)

        addSubview(doubleSpendImageView)
        doubleSpendImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(barsProgressView.snp.trailing).offset(CGFloat.margin16)
            maker.centerY.equalTo(barsProgressView)
            doubleSpendIconSizeConstraint = maker.size.equalTo(0).constraint
        }

        doubleSpendImageView.image = UIImage(named: "double_send_20")
        doubleSpendImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        doubleSpendImageView.setContentHuggingPriority(.required, for: .horizontal)
        doubleSpendImageView.isHidden = true

        addSubview(processingLabel)
        processingLabel.snp.makeConstraints { maker in
            doubleSpendIconRightMarginConstraint = maker.leading.equalTo(doubleSpendImageView.snp.trailing).offset(0).constraint
            maker.trailing.equalToSuperview()
            maker.centerY.equalTo(barsProgressView)
        }

        processingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        processingLabel.font = .subhead2
        processingLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(type: TransactionType, progress: Double, hideDoubleSpendImage: Bool) {
        let text: String
        let filledColor: UIColor

        switch type {
        case .incoming:
            text = progress == 0 ? "transactions.pending".localized : "transactions.receiving".localized
            filledColor = .themeGreenD
        case .outgoing, .sentToSelf, .approve:
            text = progress == 0 ? "transactions.pending".localized : "transactions.sending".localized
            filledColor = .themeYellowD
        }

        processingLabel.text = text
        barsProgressView.set(filledColor: filledColor)
        barsProgressView.set(progress: progress)

        doubleSpendImageView.isHidden = hideDoubleSpendImage
        doubleSpendIconSizeConstraint?.update(offset: hideDoubleSpendImage ? 0 : 20)
        doubleSpendIconRightMarginConstraint?.update(offset: hideDoubleSpendImage ? 0 : CGFloat.margin4)
    }

    func startAnimating() {
        barsProgressView.startAnimating()
    }

    func stopAnimating() {
        barsProgressView.stopAnimating()
    }

}
