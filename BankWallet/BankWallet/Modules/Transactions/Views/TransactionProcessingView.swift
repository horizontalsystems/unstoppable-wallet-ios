import UIKit
import SnapKit

class TransactionProcessingView: UIView {
    private let barsProgressView = BarsProgressView(barWidth: 4, color: .appGray50, inactiveColor: .appSteel20)
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

        barsProgressView.set(barsCount: AppTheme.progressStepsCount)

        processingLabel.font = .appSubhead2
        processingLabel.textColor = .appGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(incoming: Bool, progress: Double) {
        processingLabel.text = incoming ? "transactions.receiving".localized : "transactions.sending".localized
        barsProgressView.set(filledColor: incoming ? .appGreenD : .appYellowD)
        barsProgressView.set(progress: progress)
    }

    func startAnimating() {
        barsProgressView.startAnimating()
    }

    func stopAnimating() {
        barsProgressView.stopAnimating()
    }

}
