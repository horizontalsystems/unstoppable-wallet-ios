import UIKit
import SnapKit

class TransactionProcessingView: UIView {
    private let barsProgressView = BarsProgressView(barWidth: 4, color: .themeGray50, inactiveColor: .themeSteel20)
    private let processingLabel = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(barsProgressView)
        addSubview(processingLabel)

        barsProgressView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalTo(processingLabel)
            maker.height.equalTo(CGFloat.margin3x)
        }
        barsProgressView.set(barsCount: BarsProgressView.progressStepsCount)

        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(barsProgressView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.bottom.trailing.equalToSuperview()
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
        case .outgoing, .sentToSelf:
            text = "transactions.sending".localized
            filledColor = .themeYellowD
        case .approve:
            text = "transactions.approval".localized
            filledColor = .themeLeah
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
