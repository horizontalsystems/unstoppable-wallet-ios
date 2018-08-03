import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendReferenceItemView: BaseActionItemView {

    let referenceInputField = ReferenceInputField()
    let timeLabel = UILabel()
    let feeLabel = UILabel()
    let feeSlider = UISlider()
    var backButton = RespondButton()

    override var item: SendReferenceItem? { return _item as? SendReferenceItem }

    override func initView() {
        super.initView()
        addSubview(referenceInputField)
        referenceInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalToSuperview().offset(SendTheme.referenceInputTopMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.height.equalTo(SendTheme.referenceInputHeight)
        }

        timeLabel.font = SendTheme.timeLabelFont
        timeLabel.textColor = SendTheme.timeLabelColor
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalTo(referenceInputField.snp.bottom).offset(SendTheme.timeLabelTopMargin)
        }

        feeLabel.font = SendTheme.feeLabelFont
        feeLabel.textColor = SendTheme.feeLabelColor
        addSubview(feeLabel)
        feeLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.bottom.equalTo(timeLabel.snp.bottom)
        }

        feeSlider.minimumValue = 0
        feeSlider.maximumValue = 100
        addSubview(feeSlider)
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.top.equalTo(timeLabel.snp.bottom).offset(SendTheme.sideMargin)
        }

        backButton.textColors = [RespondButton.State.active: SendTheme.moreButtonTextColor, RespondButton.State.selected: SendTheme.moreButtonTextColor]
        backButton.titleLabel.text = "back".localized
        backButton.titleLabel.snp.remakeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.sideMargin)
            maker.top.equalToSuperview().offset(SendTheme.backButtonTopMargin)
        }
        addSubview(backButton)
        backButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(feeSlider.snp.bottom)
        }

        bind()
    }

    func bind() {
        timeLabel.text = item?.deliverTimeFrame
        feeLabel.text = item?.feeString
        backButton.onTap = item?.onBack
    }

    override func updateView() {
        super.updateView()
        bind()
    }

}
