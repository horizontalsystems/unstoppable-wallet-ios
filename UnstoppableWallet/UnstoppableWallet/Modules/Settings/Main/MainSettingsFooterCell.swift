import UIKit
import UIExtensions
import SnapKit

class MainSettingsFooterCell: UITableViewCell {
    let cellHeight: CGFloat = 130

    private let versionLabel = UILabel()
    private let logoButton = UIButton()

    var onTapLogo: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
        }

        versionLabel.textColor = .themeGray
        versionLabel.font = .caption

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(versionLabel)
            maker.top.equalTo(versionLabel.snp.bottom).offset(CGFloat.margin8)
            maker.height.equalTo(1 / UIScreen.main.scale)
        }

        separatorView.backgroundColor = .themeSteel20

        let titleLabel = UILabel()

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin4)
            maker.centerX.equalToSuperview()
        }

        titleLabel.textColor = .themeGray
        titleLabel.font = .micro
        titleLabel.text = "settings.info_subtitle".localized

        contentView.addSubview(logoButton)
        logoButton.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin32)
            maker.centerX.equalToSuperview()
        }

        logoButton.setImage(UIImage(named: "HS Logo Image"), for: .normal)
        logoButton.addTarget(self, action: #selector(onTapLogoButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapLogoButton() {
        onTapLogo?()
    }

    func set(appVersion: String) {
        versionLabel.text = "\(AppConfig.appName.uppercased()) \(appVersion)"
    }

}
