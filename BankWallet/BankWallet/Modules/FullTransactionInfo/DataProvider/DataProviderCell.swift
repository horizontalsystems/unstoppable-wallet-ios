import UIKit
import UIExtensions
import HUD
import SnapKit

class DataProviderCell: UITableViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let checkmarkImageView = TintImageView(image: UIImage(named: "Transaction Success Icon"), tintColor: SettingsTheme.checkmarkTintColor, selectedTintColor: SettingsTheme.checkmarkTintColor)
    let spinnerView = HUDProgressView(strokeLineWidth: SettingsTheme.spinnerLineWidth, radius: SettingsTheme.spinnerSideSize / 2 - SettingsTheme.spinnerLineWidth / 2, strokeColor: UIColor.cryptoGray)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SettingsTheme.cellBackground
        contentView.backgroundColor = .clear
        selectionStyle = .none

        titleLabel.font = SettingsTheme.titleFont
        titleLabel.textColor = SettingsTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalToSuperview().offset(SettingsTheme.cellMiddleMargin)
        }
        subtitleLabel.font = SettingsTheme.subtitleFont
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(SettingsTheme.subtitleTopMargin)
        }
        contentView.addSubview(spinnerView)
        spinnerView.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.size.equalTo(SettingsTheme.spinnerSideSize)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(SettingsTheme.spinnerTopMargin)
        }
        contentView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func bind(title: String, online: Bool, checking: Bool, selected: Bool) {
        titleLabel.text = title

        subtitleLabel.isHidden = checking
        spinnerView.isHidden = !checking

        if checking {
            spinnerView.startAnimating()
        } else {
            spinnerView.stopAnimating()

            if online {
                subtitleLabel.text = "full_info.source.online".localized
                subtitleLabel.textColor = SettingsTheme.onlineSubtitleColor
            } else {
                subtitleLabel.text = "full_info.source.offline".localized
                subtitleLabel.textColor = SettingsTheme.offlineSubtitleColor
            }
        }
        checkmarkImageView.isHidden = !selected
    }
}
