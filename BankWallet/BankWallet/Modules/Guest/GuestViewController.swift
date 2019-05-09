import UIKit
import SnapKit

class GuestViewController: UIViewController {
    private let delegate: IGuestViewDelegate

    var backgroundImageView = UIImageView()
    var titleImageView = UIImageView()
    var descriptionLabel = UILabel()
    var createButton = UIButton()
    var restoreButton = UIButton()
    var versionLabel = UILabel()

    init(delegate: IGuestViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(named: "Blockchain Image")

        view.addSubview(titleImageView)
        titleImageView.image = UIImage(named: "Guest Title Image")
        titleImageView.contentMode = .scaleAspectFit
        titleImageView.snp.makeConstraints { maker in
//            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(GuestTheme.titleTopMargin)
            maker.leading.equalToSuperview().offset(50)
            maker.trailing.equalToSuperview().offset(-50)
        }

        view.addSubview(descriptionLabel)
        descriptionLabel.font = GuestTheme.descriptionFont
        descriptionLabel.textColor = GuestTheme.descriptionColor
        descriptionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.titleImageView.snp.bottom).offset(GuestTheme.descriptionTopMargin)
        }

        view.addSubview(createButton)
        view.addSubview(restoreButton)
        view.addSubview(versionLabel)

        createButton.titleLabel?.font = GuestTheme.buttonFont
        createButton.setBackgroundColor(color: GuestTheme.createButtonBackground, forState: .normal)
        createButton.setTitleColor(GuestTheme.createButtonTextColor, for: .normal)
        createButton.layer.cornerRadius = GuestTheme.buttonCornerRadius
        createButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.restoreButton.snp.top).offset(-GuestTheme.createButtonBottomMargin)
            maker.height.equalTo(GuestTheme.buttonHeight)
            maker.leading.equalToSuperview().offset(GuestTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-GuestTheme.buttonSideMargin)
        }
        createButton.addTarget(self, action: #selector(createNewWalletDidTap), for: .touchUpInside)

        restoreButton.titleLabel?.font = GuestTheme.buttonFont
        restoreButton.setBackgroundColor(color: GuestTheme.restoreButtonBackground, forState: .normal)
        restoreButton.setTitleColor(GuestTheme.restoreButtonTextColor, for: .normal)
        restoreButton.layer.cornerRadius = GuestTheme.buttonCornerRadius
        restoreButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.versionLabel.snp.top).offset(-GuestTheme.restoreButtonBottomMargin)
            maker.height.equalTo(GuestTheme.buttonHeight)
            maker.leading.equalToSuperview().offset(GuestTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-GuestTheme.buttonSideMargin)
        }
        restoreButton.addTarget(self, action: #selector(restoreWalletDidTap), for: .touchUpInside)

        versionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-GuestTheme.versionBottomMargin)
        }
        versionLabel.textColor = GuestTheme.versionLabelTextColor
        versionLabel.font = GuestTheme.versionLabelFont

        delegate.viewDidLoad()

        descriptionLabel.text = "guest.description".localized
        createButton.setTitle("guest.create_wallet".localized, for: .normal)
        restoreButton.setTitle("guest.restore_wallet".localized, for: .normal)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    @objc func createNewWalletDidTap() {
        delegate.createWalletDidClick()
    }

    @objc func restoreWalletDidTap() {
        delegate.restoreWalletDidClick()
    }

}

extension GuestViewController: IGuestView {

    func set(appVersion: String) {
        versionLabel.text = "guest.version".localized(appVersion)
    }

}
