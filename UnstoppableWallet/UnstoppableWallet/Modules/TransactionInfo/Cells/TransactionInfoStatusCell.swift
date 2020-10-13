import UIKit
import ThemeKit

class TransactionInfoStatusCell: ThemeCell {
    private let titleView = TransactionInfoTitleView()

    private let statusLabel = UILabel()
    private let statusIcon = UIImageView()
    private let barsProgressView = BarsProgressView(barWidth: 4, color: .themeGray50, inactiveColor: .themeSteel20)

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        titleView.bind(text: "status".localized)

        contentView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleView.snp.trailing)
            maker.centerY.equalToSuperview()
        }

        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.textAlignment = .right
        statusLabel.font = .subhead1
        statusLabel.textColor = .themeLeah

        contentView.addSubview(statusIcon)
        statusIcon.snp.makeConstraints { maker in
            maker.leading.equalTo(statusLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        statusIcon.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(barsProgressView)
        barsProgressView.snp.makeConstraints { maker in
            maker.leading.equalTo(statusLabel.snp.trailing).offset(CGFloat.margin2x).priority(.low)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(18)
        }

        barsProgressView.set(barsCount: BarsProgressView.progressStepsCount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(status: TransactionStatus, incoming: Bool) {
        super.bind(bottomSeparatorVisible: true)

        statusIcon.isHidden = true

        barsProgressView.stopAnimating()
        barsProgressView.isHidden = true

        switch status {
        case .completed: bindCompleted()
        case .pending: bindProcessing(progress: 0, incoming: incoming)
        case .processing(let progress): bindProcessing(progress: progress, incoming: incoming)
        case .failed: bindFailed()
        }
    }

    private func bindCompleted() {
        bindIcon(image: UIImage(named: "Transaction Info Completed Icon")?.tinted(with: .themeRemus))
        statusLabel.text = "tx_info.status.confirmed".localized
    }

    private func bindProcessing(progress: Double, incoming: Bool) {
        barsProgressView.isHidden = false
        barsProgressView.set(filledColor: incoming ? .themeGreenD : .themeYellowD)
        barsProgressView.set(progress: progress)
        barsProgressView.startAnimating()

        statusLabel.text = incoming ? "transactions.receiving".localized : "transactions.sending".localized
    }

    private func bindFailed() {
        bindIcon(image: UIImage(named: "Attention Icon")?.tinted(with: .themeLucian))
        statusLabel.text = "tx_info.status.failed".localized
    }

    private func bindIcon(image: UIImage?) {
        statusIcon.isHidden = false
        statusIcon.image = image
    }

}
