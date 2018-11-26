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
        backgroundColor = TransactionInfoTheme.titleBackground

        titleLabel.font = TransactionInfoTheme.usualFont
        titleLabel.textColor = TransactionInfoTheme.usualColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(TransactionInfoTheme.regularMargin)
        }

        let wrapperView = UIView()
        wrapperView.backgroundColor = TransactionInfoTheme.hashBackground
        wrapperView.borderColor = TransactionInfoTheme.hashWrapperBorderColor
        wrapperView.borderWidth = 1 / UIScreen.main.scale
        wrapperView.cornerRadius = TransactionInfoTheme.hashCornerRadius
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(TransactionInfoTheme.middleMargin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-TransactionInfoTheme.regularMargin)
            maker.height.equalTo(TransactionInfoTheme.hashBackgroundHeight)
        }

        progressView.backgroundColor = .cryptoGreen20
        wrapperView.addSubview(progressView)
        progressView.snp.makeConstraints { maker in
            maker.top.bottom.leading.equalToSuperview()
            maker.width.equalTo(0)
        }

        statusLabel.font = TransactionInfoTheme.usualFont
        statusLabel.textColor = TransactionInfoTheme.usualColor
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
        statusLabel.textColor = TransactionInfoTheme.statusValueColor
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
