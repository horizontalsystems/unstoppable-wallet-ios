import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class TransactionStatusItemView: BaseActionItemView {
    private let titleLabel = UILabel()

    private let completeStatusWrapper = UIView()
    private let completeStatusLabel = UILabel()
    private let completeStatusIcon = UIImageView()

    private let processingWrapper = UIView()
    private let processingLabel = UILabel()
    private let barsProgressView = BarsProgressView(barWidth: 4, color: .clear, inactiveColor: .themeSteel20)

    private let failedLabel = UILabel()

    override var item: TransactionStatusItem? {
        _item as? TransactionStatusItem
    }

    override func initView() {
        super.initView()

        backgroundColor = .themeLawrence

        addSubview(titleLabel)
        addSubview(completeStatusWrapper)
        completeStatusWrapper.addSubview(completeStatusLabel)
        completeStatusWrapper.addSubview(completeStatusIcon)
        addSubview(processingWrapper)
        processingWrapper.addSubview(processingLabel)
        processingWrapper.addSubview(barsProgressView)
        addSubview(failedLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.text = "tx_info.status".localized
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray

        completeStatusWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        completeStatusLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        completeStatusLabel.font = .subhead1
        completeStatusLabel.textColor = .themeOz
        completeStatusLabel.text = "tx_info.status.confirmed".localized

        completeStatusIcon.snp.makeConstraints { maker in
            maker.leading.equalTo(completeStatusLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview()
        }
        completeStatusIcon.image = UIImage(named: "Transaction Info Completed Icon")?.tinted(with: .themeRemus)

        processingWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        processingLabel.font = .subhead1
        processingLabel.textColor = .themeOz

        barsProgressView.snp.makeConstraints { maker in
            maker.leading.equalTo(processingLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.top.trailing.bottom.equalToSuperview()
            maker.height.equalTo(20)
        }

        barsProgressView.set(barsCount: BarsProgressView.progressStepsCount)

        failedLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        failedLabel.font = .subhead1
        failedLabel.textColor = .themeLucian
        failedLabel.text = "tx_info.status.failed".localized
    }

    override func updateView() {
        super.updateView()

        guard let item = item else {
            return
        }

        if item.failed {
            processingWrapper.isHidden = true
            completeStatusWrapper.isHidden = true
            failedLabel.isHidden = false

        } else if let progress = item.progress {
            processingWrapper.isHidden = false
            completeStatusWrapper.isHidden = true
            failedLabel.isHidden = true

            processingLabel.text = item.type == .incoming ? "transactions.receiving".localized : "transactions.sending".localized

            barsProgressView.set(filledColor: item.type == .incoming ? .themeGreenD : .themeYellowD)
            barsProgressView.set(progress: progress)

        } else {
            completeStatusWrapper.isHidden = false
            processingWrapper.isHidden = true
            failedLabel.isHidden = true
        }
    }

}
