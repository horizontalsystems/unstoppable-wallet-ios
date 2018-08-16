import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionTitleItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var coinIconImageView: TintImageView = TintImageView(image: nil, tintColor: TransactionInfoTheme.coinIconTintColor, selectedTintColor: TransactionInfoTheme.coinIconTintColor)
    var infoButton = RespondView()

    override var item: TransactionTitleItem? { return _item as? TransactionTitleItem }

    override func initView() {
        super.initView()
        backgroundColor = TransactionInfoTheme.titleBackground

        titleLabel.font = TransactionInfoTheme.titleFont
        titleLabel.textColor = TransactionInfoTheme.titleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
            maker.centerY.equalToSuperview()
        }

        let infoIconImageView: TintImageView = TintImageView(image: UIImage(named: "Transaction Full Info Icon"), tintColor: TransactionInfoTheme.transactionInfoTint, selectedTintColor: TransactionInfoTheme.transactionInfoSelectedTint)
        infoButton.delegate = infoIconImageView
        addSubview(infoButton)
        infoButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(TransactionInfoTheme.infoButtonWidth)
        }
        infoButton.handleTouch = item?.onInfo
        infoButton.addSubview(infoIconImageView)
        infoIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }
    }

    override func updateView() {
        super.updateView()
        titleLabel.text = item?.title

        coinIconImageView.image = item?.coinIcon
    }

}
