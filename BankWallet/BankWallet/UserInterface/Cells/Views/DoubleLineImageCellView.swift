import UIKit
import SnapKit

class DoubleLineImageCellView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageView)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(SettingsTheme.cellBigMargin)
        }

        titleLabel.font = SettingsTheme.titleFont
        titleLabel.textColor = SettingsTheme.titleColor
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(SettingsTheme.cellBigMargin)
            maker.trailing.equalToSuperview().offset(-SettingsTheme.cellBigMargin)
            maker.top.equalToSuperview().offset(SettingsTheme.cellMiddleMargin)
        }

        subtitleLabel.font = SettingsTheme.subtitleFont
        subtitleLabel.textColor = SettingsTheme.subtitleColor
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(SettingsTheme.cellBigMargin)
            maker.trailing.equalToSuperview().offset(-SettingsTheme.cellBigMargin)
            maker.top.equalTo(titleLabel.snp.bottom).offset(SettingsTheme.subtitleTopMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, title: String?, subtitle: String?) {
        imageView.image = image
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}
