import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionStatusItemView: BaseActionItemView {
    private let titleLabel = UILabel()

    private let completedWrapper = UIView()
    private let completedLabel = UILabel()
    private let completedIcon = UIImageView()

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
        titleLabel.textColor = TransactionInfoTheme.itemTitleColor

        addSubview(completedWrapper)
        completedWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(TransactionInfoTheme.regularMargin)
        }

        completedWrapper.addSubview(completedLabel)
        completedLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        completedLabel.text = "tx_info.status.confirmed".localized
        completedLabel.textColor = TransactionInfoTheme.completeStatusColor
        completedLabel.font = TransactionInfoTheme.statusTextFont

        completedWrapper.addSubview(completedIcon)
        completedIcon.snp.makeConstraints { maker in
            maker.leading.equalTo(completedLabel.snp.trailing).offset(TransactionInfoTheme.smallMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview()
        }

        completedIcon.image = UIImage(named: "Transaction Info Completed Icon")?.tinted(with: .cryptoGreen)

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

        processingLabel.textColor = TransactionInfoTheme.completeStatusColor
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

        if let progress = item.progress {
            processingWrapper.isHidden = false
            completedWrapper.isHidden = true

            processingLabel.text = item.incoming ? "transactions.receiving".localized : "transactions.sending".localized

            barsProgressView.set(filledColor: item.incoming ? .appGreenD : .appYellowD)
            barsProgressView.set(progress: progress)
        } else {
            completedWrapper.isHidden = false
            processingWrapper.isHidden = true

        }
    }

}
