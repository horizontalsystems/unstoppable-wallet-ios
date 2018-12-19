import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionTitleItemView: BaseActionItemView {

    var dateLabel = UILabel()
    var idLabel = UILabel()

    override var item: TransactionTitleItem? { return _item as? TransactionTitleItem }

    override func initView() {
        super.initView()

        let titleLabel = UILabel()
        titleLabel.text = "tx_info.title".localized
        titleLabel.font = TransactionInfoTheme.titleFont
        titleLabel.textColor = TransactionInfoTheme.titleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
            maker.top.equalToSuperview().offset(TransactionInfoTheme.middleMargin)
        }

        dateLabel.font = TransactionInfoTheme.dateFont
        dateLabel.textColor = TransactionInfoTheme.dateColor
        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
            maker.top.equalTo(titleLabel.snp.bottom)
        }

        let infoButton = RespondButton()
        infoButton.titleLabel.removeFromSuperview()
        addSubview(infoButton)
        infoButton.borderWidth = 1 / UIScreen.main.scale
        infoButton.borderColor = TransactionInfoTheme.hashButtonBorderColor
        infoButton.cornerRadius = TransactionInfoTheme.hashButtonCornerRadius
        infoButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.leading.equalTo(self.dateLabel.snp.trailing).offset(TransactionInfoTheme.largeMargin)
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
        idTitleLabel.textColor = TransactionInfoTheme.hashButtonTextColor
        idTitleLabel.text = "#"

        infoButton.addSubview(idLabel)
        idLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(idTitleLabel.snp.trailing).offset(TransactionInfoTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
        }
        idLabel.font = TransactionInfoTheme.itemTitleFont
        idLabel.textColor = TransactionInfoTheme.hashButtonTextColor
        idLabel.lineBreakMode = .byTruncatingMiddle
    }

    override func updateView() {
        super.updateView()
        let date = item?.date.map { DateHelper.instance.formatTransactionInfoTime(from: $0) } ?? "n/a"
        dateLabel.text = date
        idLabel.text = item?.transactionId
    }

}
