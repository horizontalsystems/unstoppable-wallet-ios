import UIKit
import SnapKit

class GuestViewController: UIViewController {
    private let delegate: IGuestViewDelegate

    var backgroundImageView = UIImageView()
    var titleLabel = UILabel()
    var createButton = UIButton()
    var importButton = UIButton()
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

        view.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-GuestTheme.versionBottomMargin)
        }
        versionLabel.textColor = GuestTheme.versionLabelTextColor
        versionLabel.font = GuestTheme.versionLabelFont

        view.addSubview(importButton)
        importButton.titleLabel?.font = GuestTheme.buttonFont
        importButton.setBackgroundColor(color: GuestTheme.importButtonBackground, forState: .normal)
        importButton.setTitleColor(GuestTheme.importButtonTextColor, for: .normal)
        importButton.layer.cornerRadius = GuestTheme.buttonCornerRadius
        importButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.versionLabel.snp.top).offset(-GuestTheme.importButtonBottomMargin)
            maker.height.equalTo(GuestTheme.buttonHeight)
            maker.leading.equalToSuperview().offset(GuestTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-GuestTheme.buttonSideMargin)
        }
        importButton.addTarget(self, action: #selector(restoreWalletDidTap), for: .touchUpInside)

        view.addSubview(createButton)
        createButton.titleLabel?.font = GuestTheme.buttonFont
        createButton.setBackgroundColor(color: GuestTheme.createButtonBackground, forState: .normal)
        createButton.setTitleColor(GuestTheme.createButtonTextColor, for: .normal)
        createButton.layer.cornerRadius = GuestTheme.buttonCornerRadius
        createButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.importButton.snp.top).offset(-GuestTheme.createButtonBottomMargin)
            maker.height.equalTo(GuestTheme.buttonHeight)
            maker.leading.equalToSuperview().offset(GuestTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-GuestTheme.buttonSideMargin)
        }
        createButton.addTarget(self, action: #selector(createNewWalletDidTap), for: .touchUpInside)

        view.addSubview(titleLabel)
        titleLabel.font = GuestTheme.titleFont
        titleLabel.textColor = GuestTheme.titleColor
        titleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(self.createButton.snp.top).offset(-GuestTheme.titleBottomMargin)
        }

        delegate.viewDidLoad()

        titleLabel.text = "guest.title".localized
        createButton.setTitle("guest.create_wallet".localized, for: .normal)
        importButton.setTitle("guest.restore_wallet".localized, for: .normal)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
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
        versionLabel.text = appVersion
    }

}
