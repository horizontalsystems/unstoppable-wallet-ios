import UIKit
import SnapKit

class WelcomeScreenViewController: WalletViewController {
    private let delegate: IWelcomeScreenViewDelegate

    var backgroundImageView = UIImageView()
    var createButton = RespondButton()
    var restoreButton = RespondButton()
    var versionLabel = UILabel()

    init(delegate: IWelcomeScreenViewDelegate) {
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
        backgroundImageView.contentMode = .center
//        backgroundImageView.image = UIImage(named: "Blockchain Image")

        view.addSubview(createButton)
        view.addSubview(restoreButton)
        view.addSubview(versionLabel)

        createButton.onTap = { [weak self] in self?.didTapCreate() }
        createButton.backgrounds = ButtonTheme.greenBackgroundDictionary
        createButton.textColors = ButtonTheme.textColorDictionary
        createButton.titleLabel.text = "welcome.create_wallet".localized
        createButton.cornerRadius = WelcomeTheme.buttonCornerRadius

        createButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.restoreButton.snp.top).offset(-WelcomeTheme.createButtonBottomMargin)
            maker.height.equalTo(WelcomeTheme.buttonHeight)
            maker.leading.equalToSuperview().offset(WelcomeTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-WelcomeTheme.buttonSideMargin)
        }

        restoreButton.onTap = { [weak self] in self?.didTapRestore() }
        restoreButton.backgrounds = ButtonTheme.yellowBackgroundDictionary
        restoreButton.textColors = ButtonTheme.textColorDictionary
        restoreButton.titleLabel.text = "welcome.restore_wallet".localized
        restoreButton.cornerRadius = WelcomeTheme.buttonCornerRadius

        restoreButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.versionLabel.snp.top).offset(-WelcomeTheme.restoreButtonBottomMargin)
            maker.height.equalTo(WelcomeTheme.buttonHeight)
            maker.leading.equalToSuperview().offset(WelcomeTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-WelcomeTheme.buttonSideMargin)
        }

        versionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-WelcomeTheme.versionBottomMargin)
        }
        versionLabel.textColor = WelcomeTheme.versionLabelTextColor
        versionLabel.font = WelcomeTheme.versionLabelFont

        delegate.viewDidLoad()
    }

    func didTapCreate() {
        delegate.didTapCreate()
    }

    func didTapRestore() {
        delegate.didTapRestore()
    }

}

extension WelcomeScreenViewController: IWelcomeScreenView {

    func set(appVersion: String) {
        versionLabel.text = "guest.version".localized(appVersion)
    }

}
