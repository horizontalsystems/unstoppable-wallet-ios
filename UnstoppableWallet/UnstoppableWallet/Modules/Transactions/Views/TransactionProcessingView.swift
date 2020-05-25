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
        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(barsProgressView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.bottom.trailing.equalToSuperview()
        }

        barsProgressView.set(barsCount: BarsProgressView.progressStepsCount)

        processingLabel.font = .subhead2
        processingLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(type: TransactionType, progress: Double) {
        processingLabel.text = type == .incoming ? "transactions.receiving".localized : "transactions.sending".localized
        barsProgressView.set(filledColor: type == .incoming ? .themeGreenD : .themeYellowD)
        barsProgressView.set(progress: progress)
    }

    func startAnimating() {
        barsProgressView.startAnimating()
    }

    func stopAnimating() {
        barsProgressView.stopAnimating()
    }

}
