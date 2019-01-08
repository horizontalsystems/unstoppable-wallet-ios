import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionTitleItemView: BaseActionItemView {

    let titleLabel = UILabel()
    let idLabel = UILabel()

    override var item: TransactionTitleItem? { return _item as? TransactionTitleItem }

    override func initView() {
        super.initView()

        titleLabel.text = "tx_info.title".localized
        titleLabel.font = TransactionInfoTheme.titleFont
        titleLabel.textColor = TransactionInfoTheme.titleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
            maker.centerY.equalToSuperview()
        }

        let infoButton = RespondButton()
        infoButton.titleLabel.removeFromSuperview()
        addSubview(infoButton)
        infoButton.borderWidth = 1 / UIScreen.main.scale
        infoButton.borderColor = TransactionInfoTheme.hashButtonBorderColor
        infoButton.cornerRadius = TransactionInfoTheme.hashButtonCornerRadius
        infoButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.hashButtonMargin)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(TransactionInfoTheme.hashButtonHeight)
        }
        infoButton.onTap = item?.onIdTap
        infoButton.backgrounds = [RespondButton.State.active: TransactionInfoTheme.hashButtonBackground, RespondButton.State.selected: TransactionInfoTheme.hashButtonBackgroundSelected]

        let idTitleLabel = UILabel()
        infoButton.addSubview(idTitleLabel)
        idTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
        }
        idTitleLabel.font = TransactionInfoTheme.itemTitleFont
        idTitleLabel.textColor = TransactionInfoTheme.hashButtonHashTextColor
        idTitleLabel.text = "#"

        infoButton.addSubview(idLabel)
        idLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(idTitleLabel.snp.trailing).offset(TransactionInfoTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
        }
        idLabel.font = TransactionInfoTheme.itemValueFont
        idLabel.textColor = TransactionInfoTheme.itemValueColor
        idLabel.lineBreakMode = .byTruncatingMiddle
    }

    override func updateView() {
        super.updateView()

        idLabel.text = item?.transactionId
    }

}
