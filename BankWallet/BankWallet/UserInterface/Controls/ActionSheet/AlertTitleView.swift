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
            maker.leading.top.equalToSuperview().offset(CGFloat.margin3x)
        }
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentHuggingPriority(.required, for: .vertical)

        addSubview(titleLabel)
        titleLabel.font = .headline2
        titleLabel.textColor = .themeOz
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }
        addSubview(subtitleLabel)
        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(3)
        }

        addSubview(closeButton)
        closeButton.setImage(UIImage(named: "Close Icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .themeGray
        closeButton.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.size.equalTo(24 + CGFloat.margin2x * 2)
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
