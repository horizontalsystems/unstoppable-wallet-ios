import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionFromToHashItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var valueLabel = UILabel()
    var avatarImageView = UIImageView(image: UIImage(named: "Transaction Info Avatar Placeholder"))

    override var item: TransactionFromToHashItem? { return _item as? TransactionFromToHashItem
    }

    override func initView() {
        super.initView()
        backgroundColor = TransactionInfoTheme.titleBackground

        titleLabel.font = TransactionInfoTheme.usualFont
        titleLabel.textColor = TransactionInfoTheme.usualColor
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        let wrapperView = RespondButton()
        wrapperView.titleLabel.removeFromSuperview()
        wrapperView.onTap = item?.onHashTap
        wrapperView.backgrounds = [RespondButton.State.active: TransactionInfoTheme.hashBackground, RespondButton.State.selected: TransactionInfoTheme.hashBackgroundSelected]
        wrapperView.borderColor = TransactionInfoTheme.hashWrapperBorderColor
        wrapperView.borderWidth = 1 / UIScreen.main.scale
        wrapperView.cornerRadius = TransactionInfoTheme.hashCornerRadius
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.largeMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.height.equalTo(TransactionInfoTheme.hashBackgroundHeight)
        }

        wrapperView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
        }

        valueLabel.font = TransactionInfoTheme.usualFont
        valueLabel.textColor = TransactionInfoTheme.hashColor
        valueLabel.lineBreakMode = .byTruncatingMiddle
        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(TransactionInfoTheme.middleMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.middleMargin)
        }
    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title
        valueLabel.text = item?.value
    }

}
