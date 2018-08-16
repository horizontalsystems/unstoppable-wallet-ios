import UIKit
import SnapKit

class SettingsInfoFooter: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        print("init")
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        let titleLabel = UILabel()
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SettingsTheme.infoTitleTopMargin)
            maker.centerX.equalToSuperview()
        }
        titleLabel.textColor = SettingsTheme.infoTitleColor
        titleLabel.font = SettingsTheme.infoTitleFont
        titleLabel.text = "settings.info.title".localized

        let imageView = UIImageView()
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(SettingsTheme.infoImageTopMargin)
            maker.centerX.equalToSuperview()
        }
        imageView.image = UIImage(named: "Logo Image")

        let linkButton = RespondButton(onTap: {
            print("tap link")
        })
        linkButton.titleLabel.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        linkButton.backgrounds = [RespondButton.State.active: .clear, RespondButton.State.selected: .clear, RespondButton.State.disabled: .clear]
        linkButton.textColors =  [RespondButton.State.active: SettingsTheme.infoLinkColor, RespondButton.State.selected: SettingsTheme.infoSelectedLinkColor, RespondButton.State.disabled: SettingsTheme.infoLinkColor]
        let linkString: NSAttributedString = NSAttributedString(string: "settings.info.link".localized, attributes: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue, .font: SettingsTheme.infoLinkFont])
        linkButton.titleLabel.attributedText = linkString
        contentView.addSubview(linkButton)
        linkButton.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom)
            maker.height.equalTo(SettingsTheme.infoLinkButtonHeight)
            maker.centerX.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
