import UIKit
import ActionSheet
import SnapKit

class AlertTitleView: UIView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton()

    private var onClose: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(AppTheme.alertMediumMargin)
            maker.size.equalTo(AppTheme.coinIconSize)
        }

        addSubview(titleLabel)
        titleLabel.font = AppTheme.alertTitleFont
        titleLabel.textColor = AppTheme.alertTitleColor
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(AppTheme.alertSmallMargin)
            maker.top.equalToSuperview().offset(AppTheme.alertMediumMargin)
        }
        addSubview(subtitleLabel)
        subtitleLabel.font = AppTheme.alertSubtitleFont
        subtitleLabel.textColor = AppTheme.alertSubtitleColor
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(AppTheme.alertSubtitleTopMargin)
        }

        addSubview(closeButton)
        closeButton.setImage(UIImage(named: "Close Icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppTheme.closeButtonColor
        closeButton.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(AppTheme.alertMediumMargin)
            maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapClose() {
        onClose?()
    }

    func bind(title: String?, subtitle: String?, image: UIImage?, tintColor: UIColor?, onClose: (() -> ())?) {
        titleLabel.text = title
        bind(subtitle: subtitle)

        var image = image
        if let color = tintColor {
            iconImageView.tintColor = color
            image = image?.withRenderingMode(.alwaysTemplate)
        }
        iconImageView.image = image

        self.onClose = onClose
    }

    func bind(subtitle: String?) {
        subtitleLabel.text = subtitle
    }

}
