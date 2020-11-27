import UIKit
import SnapKit

class TransactionProcessingView: UIView {
    private let barsProgressView = BarsProgressView(color: .themeGray50, inactiveColor: .themeSteel20)
    private let processingLabel = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(barsProgressView)
        barsProgressView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        barsProgressView.set(barsCount: BarsProgressView.progressStepsCount)

        addSubview(processingLabel)
        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(barsProgressView.snp.trailing).offset(CGFloat.margin16)
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

    func bind(type: TransactionType, progress: Double) {
        let text: String
        let filledColor: UIColor

        switch type {
        case .incoming:
            text = "transactions.receiving".localized
            filledColor = .themeGreenD
        case .outgoing, .sentToSelf, .approve:
            text = "transactions.pending".localized
            filledColor = .themeYellowD
        }

        processingLabel.text = text
        barsProgressView.set(filledColor: filledColor)
        barsProgressView.set(progress: progress)
    }

    func startAnimating() {
        barsProgressView.startAnimating()
    }

    func stopAnimating() {
        barsProgressView.stopAnimating()
    }

}
