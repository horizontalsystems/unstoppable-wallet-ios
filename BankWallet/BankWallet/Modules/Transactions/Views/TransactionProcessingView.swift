import UIKit
import SnapKit

class TransactionProcessingView: UIView {
    private static let stepsCount = 3

    private let barsProgressView = BarsProgressView(count: TransactionProcessingView.stepsCount, barWidth: 4, color: .appGray50, inactiveColor: .appSteel20)
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
        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(barsProgressView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.bottom.trailing.equalToSuperview()
        }

        processingLabel.font = .appSubhead2
        processingLabel.textColor = .appGray
        processingLabel.text = "transactions.processing".localized
        barsProgressView.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(status: TransactionStatus) {
        guard case let .processing(progress) = status else {
            isHidden = true
            barsProgressView.isAnimating = false

            return
        }

        isHidden = false
        barsProgressView.filledCount = Int(Double(TransactionProcessingView.stepsCount) * progress)
        barsProgressView.isAnimating = true
    }

}
