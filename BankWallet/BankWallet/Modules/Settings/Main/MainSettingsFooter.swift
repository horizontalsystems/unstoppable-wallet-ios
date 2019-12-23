import UIKit
import UIExtensions
import SnapKit

class MainSettingsFooter: UITableViewHeaderFooterView {
    private let versionLabel = UILabel()
    private let logoButton = RespondView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        contentView.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin8x)
            maker.centerX.equalToSuperview()
        }
        versionLabel.textColor = .appGray
        versionLabel.font = .appCaption

        let separatorView = UIView()
        separatorView.backgroundColor = .appGray
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(versionLabel)
            maker.top.equalTo(versionLabel.snp.bottom).offset(CGFloat.margin1x)
            maker.height.equalTo(1 / UIScreen.main.scale)
        }

        let titleLabel = UILabel()
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin1x)
            maker.centerX.equalToSuperview()
        }
        titleLabel.textColor = .appGray
        titleLabel.font = .appCaption
        titleLabel.text = "settings.info_subtitle".localized

        let imageView: TintImageView = TintImageView(image: UIImage(named: "Logo Image"), tintColor: .appGray, selectedTintColor: .appSteelLight)
        logoButton.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        logoButton.delegate = imageView

        contentView.addSubview(logoButton)
        logoButton.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8x)
            maker.centerX.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(appVersion: String?, handleTouch: (() -> ())? = nil) {
        var versionText = "settings.info_title".localized

        if let appVersion = appVersion {
            versionText += " \(appVersion)"
        }

        versionLabel.text = versionText
        logoButton.handleTouch = handleTouch
    }

}
