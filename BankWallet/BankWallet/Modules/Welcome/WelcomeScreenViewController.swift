import UIKit
import SnapKit

class WelcomeScreenViewController: UIViewController {
    private let delegate: IWelcomeScreenViewDelegate

    private let backgroundImageView = UIImageView()
    private let logoImageView = UIImageView()
    private let createButton = UIButton()
    private let restoreButton = UIButton()
    private let versionLabel = UILabel()

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
        view.addSubview(logoImageView)
        view.addSubview(createButton)
        view.addSubview(restoreButton)
        view.addSubview(versionLabel)

        backgroundImageView.image = UIImage(named: "Welcome Background")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        logoImageView.image = UIImage(named: "Welcome Logo")
        logoImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.createButton.snp.top).offset(-WelcomeTheme.logoBottomMargin)
        }

        createButton.setTitle("welcome.new_wallet".localized, for: .normal)
        createButton.titleLabel?.font = ButtonTheme.font
        createButton.setBackgroundColor(color: WelcomeTheme.buttonBackground, forState: .normal)
        createButton.setBackgroundColor(color: WelcomeTheme.buttonBackgroundHighlighted, forState: .highlighted)
        createButton.cornerRadius = WelcomeTheme.buttonCornerRadius
        createButton.addTarget(self, action: #selector(didTapNew), for: .touchUpInside)
        createButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WelcomeTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-WelcomeTheme.buttonSideMargin)
            maker.bottom.equalTo(self.restoreButton.snp.top).offset(-WelcomeTheme.createButtonBottomMargin)
            maker.height.equalTo(WelcomeTheme.buttonHeight)
        }

        restoreButton.setTitle("welcome.restore_wallet".localized, for: .normal)
        restoreButton.titleLabel?.font = ButtonTheme.font
        restoreButton.setBackgroundColor(color: WelcomeTheme.buttonBackground, forState: .normal)
        restoreButton.setBackgroundColor(color: WelcomeTheme.buttonBackgroundHighlighted, forState: .highlighted)
        restoreButton.cornerRadius = WelcomeTheme.buttonCornerRadius
        restoreButton.addTarget(self, action: #selector(didTapRestore), for: .touchUpInside)
        restoreButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(WelcomeTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-WelcomeTheme.buttonSideMargin)
            maker.bottom.equalTo(self.versionLabel.snp.top).offset(-WelcomeTheme.restoreButtonBottomMargin)
            maker.height.equalTo(WelcomeTheme.buttonHeight)
        }

        versionLabel.textColor = WelcomeTheme.versionLabelTextColor
        versionLabel.font = WelcomeTheme.versionLabelFont
        versionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-WelcomeTheme.versionBottomMargin)
        }

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func didTapNew() {
        delegate.didTapCreate()
    }

    @objc func didTapRestore() {
        delegate.didTapRestore()
    }

}

extension WelcomeScreenViewController: IWelcomeScreenView {

    func set(appVersion: String) {
        versionLabel.text = "welcome.version".localized(appVersion)
    }

}
