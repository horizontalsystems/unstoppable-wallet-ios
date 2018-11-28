import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class SendConfirmationAddressItemView: BaseActionItemView {
    let valueLabel = UILabel()
    let avatarImageView = UIImageView(image: UIImage(named: "Transaction Info Avatar Placeholder"))

    override var item: SendConfirmationAddressItem? { return _item as? SendConfirmationAddressItem }

    override func initView() {
        super.initView()

        let wrapperView = RespondButton()
        wrapperView.onTap = item?.onHashTap
        wrapperView.backgrounds = [RespondButton.State.active: SendTheme.hashBackground, RespondButton.State.selected: SendTheme.hashBackgroundSelected]
        wrapperView.borderColor = SendTheme.hashWrapperBorderColor
        wrapperView.borderWidth = 1 / UIScreen.main.scale
        wrapperView.cornerRadius = SendTheme.hashCornerRadius
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.height.equalTo(SendTheme.hashBackgroundHeight)
        }

        wrapperView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.smallMargin)
            maker.centerY.equalToSuperview()
        }

        valueLabel.font = SendTheme.valueFont
        valueLabel.textColor = SendTheme.hashColor
        valueLabel.lineBreakMode = .byTruncatingMiddle
        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.smallMargin)
        }
    }

    override func updateView() {
        super.updateView()

        valueLabel.text = item?.address
    }

}
