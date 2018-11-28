import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendFeeItemView: BaseActionItemView {
    private let feeLabel = UILabel()
    private let convertedFeeLabel = UILabel()

    override var item: SendFeeItem? { return _item as? SendFeeItem }

    override func initView() {
        super.initView()

        addSubview(feeLabel)
        addSubview(convertedFeeLabel)

        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor
        feeLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(SendTheme.margin)
        }

        convertedFeeLabel.font = SendTheme.feeFont
        convertedFeeLabel.textColor = SendTheme.feeColor
        convertedFeeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        convertedFeeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.leading.equalTo(feeLabel.snp.trailing).offset(SendTheme.margin)
        }

        item?.bindFee = { [weak self] in
            self?.feeLabel.text = $0.map { "send.fee".localized + ": \($0)" }
        }
        item?.bindConvertedFee = { [weak self] in
            self?.convertedFeeLabel.text = $0
        }
    }

}
