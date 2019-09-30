import UIKit
import SnapKit

class AboutSettingsViewController: WalletViewController {

    init() {
        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_about.title".localized

        let scrollView = UIScrollView()

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview()
        }

        let container = UIView()

        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(scrollView)
            maker.leading.trailing.equalTo(view)
        }

        let imageView = UIImageView(image: UIImage(named: "App Icon"))
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        container.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin6x)
        }

        let titleLabel = UILabel()
        titleLabel.text = "settings_about.app_title".localized
        titleLabel.font = .appHeadline1
        titleLabel.textColor = .appOz

        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.top).inset(CGFloat.margin2x)
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        let subtitleLabel = UILabel()
        subtitleLabel.text = "settings_about.app_subtitle".localized
        subtitleLabel.font = .appSubhead2
        subtitleLabel.textColor = .appGray

        container.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        let separatorView = UIView()
        separatorView.backgroundColor = .appSteel20

        container.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin6x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        let headerLabel = UILabel()
        headerLabel.text = "settings_about.terms_privacy_subtitle".localized
        headerLabel.font = .appHeadline2
        headerLabel.textColor = .appJacob

        container.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { maker in
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin6x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        let textLabel = UILabel()
        textLabel.text = "settings_about.terms_privacy_text".localized
        textLabel.numberOfLines = 0
        textLabel.font = .appBody
        textLabel.textColor = .appLeah

        container.addSubview(textLabel)
        textLabel.snp.makeConstraints { maker in
            maker.top.equalTo(headerLabel.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin8x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }
    }

}
