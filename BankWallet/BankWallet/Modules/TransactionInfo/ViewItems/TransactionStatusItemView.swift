import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TransactionStatusItemView: BaseActionItemView {

    var titleLabel = UILabel()
    var statusLabel = UILabel()
    var progressView = UIView()
    var statusImageView = TintImageView(image: nil, selectedImage: nil)

    override var item: TransactionStatusItem? { return _item as? TransactionStatusItem }

    override func initView() {
        super.initView()

        backgroundColor = TransactionInfoTheme.itemBackground

        titleLabel.font = TransactionInfoTheme.itemTitleFont
        titleLabel.textColor = TransactionInfoTheme.itemTitleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        let wrapperView = UIView()
        wrapperView.backgroundColor = TransactionInfoTheme.hashButtonBackground
        wrapperView.borderColor = TransactionInfoTheme.hashButtonBorderColor
        wrapperView.borderWidth = 1 / UIScreen.main.scale
        wrapperView.cornerRadius = TransactionInfoTheme.hashButtonCornerRadius
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.height.equalTo(TransactionInfoTheme.hashButtonHeight)
        }

        progressView.backgroundColor = .cryptoGreen20
        wrapperView.addSubview(progressView)
        progressView.snp.makeConstraints { maker in
            maker.top.bottom.leading.equalToSuperview()
            maker.width.equalTo(0)
        }

        statusLabel.font = TransactionInfoTheme.itemTitleFont
        wrapperView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.middleMargin)
        }

        wrapperView.addSubview(statusImageView)
        statusImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.middleMargin)
            maker.trailing.equalTo(self.statusLabel.snp.leading).offset(0)
            maker.width.equalTo(0)
            maker.height.equalTo(TransactionInfoTheme.statusImageHeight)
        }
    }

    override func updateView() {
        super.updateView()

        titleLabel.text = item?.title
        statusLabel.text = item?.value?.uppercased()
        statusLabel.textColor = TransactionInfoTheme.hashButtonTextColor
        statusImageView.image = item?.valueImage
        statusImageView.tintColor = item?.valueImageTintColor

        let hasImage = item?.valueImage != nil
        statusImageView.snp.updateConstraints { maker in
            maker.trailing.equalTo(self.statusLabel.snp.leading).offset(hasImage ? -TransactionInfoTheme.smallMargin : 0)
            maker.width.equalTo(hasImage ? TransactionInfoTheme.statusImageWidth : 0)
        }

        let progress = item?.progress ?? 0
        progressView.snp.remakeConstraints { maker in
            maker.top.bottom.leading.equalToSuperview()
            maker.width.equalToSuperview().multipliedBy(progress)
        }
    }

}
