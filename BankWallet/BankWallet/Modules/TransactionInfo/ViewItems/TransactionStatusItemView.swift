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
    private let barsProgressView = BarsProgressView(barWidth: 4, color: .clear, inactiveColor: .appSteel20)

    override var item: TransactionStatusItem? {
        _item as? TransactionStatusItem
    }

    override func initView() {
        super.initView()

        backgroundColor = .appLawrence

        addSubview(titleLabel)
        addSubview(finalStatusWrapper)
        finalStatusWrapper.addSubview(finalStatusLabel)
        finalStatusWrapper.addSubview(finalStatusIcon)
        addSubview(processingWrapper)
        processingWrapper.addSubview(processingLabel)
        processingWrapper.addSubview(barsProgressView)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.text = "tx_info.status".localized
        titleLabel.font = .appSubhead2
        titleLabel.textColor = .appGray

        finalStatusWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        finalStatusLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        finalStatusLabel.font = .appSubhead1
        finalStatusLabel.textColor = .appOz

        finalStatusIcon.snp.makeConstraints { maker in
            maker.leading.equalTo(finalStatusLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview()
        }

        processingWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        processingLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        processingLabel.textColor = .appOz
        processingLabel.font = .appSubhead1

        barsProgressView.snp.makeConstraints { maker in
            maker.leading.equalTo(processingLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.top.trailing.bottom.equalToSuperview()
            maker.height.equalTo(20)
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

            processingLabel.text = item.type == .incoming ? "transactions.receiving".localized : "transactions.sending".localized

            barsProgressView.set(filledColor: item.type == .incoming ? .appGreenD : .appYellowD)
            barsProgressView.set(progress: progress)

        } else {
            finalStatusWrapper.isHidden = false
            processingWrapper.isHidden = true

            finalStatusIcon.image = UIImage(named: "Transaction Info Completed Icon")?.tinted(with: .appRemus)

            finalStatusLabel.text = "tx_info.status.confirmed".localized
        }
    }

}
