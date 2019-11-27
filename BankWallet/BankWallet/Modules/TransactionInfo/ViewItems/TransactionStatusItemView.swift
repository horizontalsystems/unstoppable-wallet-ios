import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionStatusItemView: BaseActionItemView {
    private let titleLabel = UILabel()

    private let finalStatusWrapper = UIView()
    private let finalStatusLabel = UILabel()
    private let finalStatusIcon = UIImageView()

    private let processingWrapper = UIView()
    private let processingLabel = UILabel()
    private let barsProgressView = BarsProgressView(barWidth: 4, color: .clear, inactiveColor: .cryptoSteel20)

    override var item: TransactionStatusItem? {
        _item as? TransactionStatusItem
    }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        titleLabel.text = "tx_info.status".localized
        titleLabel.font = TransactionInfoTheme.itemTitleFont

        addSubview(finalStatusWrapper)
        finalStatusWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(TransactionInfoTheme.regularMargin)
        }

        finalStatusWrapper.addSubview(finalStatusLabel)
        finalStatusLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        finalStatusLabel.font = TransactionInfoTheme.statusTextFont
        finalStatusLabel.textColor = .crypto_Bars_Dark

        finalStatusWrapper.addSubview(finalStatusIcon)
        finalStatusIcon.snp.makeConstraints { maker in
            maker.leading.equalTo(finalStatusLabel.snp.trailing).offset(TransactionInfoTheme.smallMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview()
        }

        addSubview(processingWrapper)
        processingWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(TransactionInfoTheme.regularMargin)
        }

        processingWrapper.addSubview(processingLabel)
        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        processingLabel.textColor = .crypto_Bars_Dark
        processingLabel.font = TransactionInfoTheme.statusTextFont

        processingWrapper.addSubview(barsProgressView)
        barsProgressView.snp.makeConstraints { maker in
            maker.leading.equalTo(processingLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.top.trailing.bottom.equalToSuperview()
            maker.height.equalTo(TransactionInfoTheme.barsProgressHeight)
        }

        barsProgressView.set(barsCount: AppTheme.progressStepsCount)
    }

    override func updateView() {
        super.updateView()

        guard let item = item else {
            return
        }

        if item.failed {
            processingWrapper.isHidden = true
            finalStatusWrapper.isHidden = false

            finalStatusIcon.image = UIImage(named: "Transaction Info Failed Icon")?.tinted(with: .appLucian)

            finalStatusLabel.text = "tx_info.status.failed".localized

        } else if let progress = item.progress {
            processingWrapper.isHidden = false
            finalStatusWrapper.isHidden = true

            processingLabel.text = item.incoming ? "transactions.receiving".localized : "transactions.sending".localized

            barsProgressView.set(filledColor: item.incoming ? .appGreenD : .appYellowD)
            barsProgressView.set(progress: progress)

        } else {
            finalStatusWrapper.isHidden = false
            processingWrapper.isHidden = true

            finalStatusIcon.image = UIImage(named: "Transaction Info Completed Icon")?.tinted(with: .cryptoGreen)

            finalStatusLabel.text = "tx_info.status.confirmed".localized
        }
    }

}
