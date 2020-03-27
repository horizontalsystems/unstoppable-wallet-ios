import UIKit
import SnapKit

class WelcomeScreenViewController: UIViewController {
    private let delegate: IWelcomeScreenViewDelegate

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

        view.backgroundColor = .themeDarker

        let titleWrapper = UIView()

        view.addSubview(titleWrapper)
        titleWrapper.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalToSuperview().dividedBy(2)
        }

        let titleLabel = UILabel()

        titleWrapper.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.text = "Unstoppable\nWallet"
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = .title2
        titleLabel.textColor = .themeLight

        let createButton = UIButton.appYellow

        view.addSubview(createButton)
        createButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        createButton.setTitle("welcome.new_wallet".localized, for: .normal)
        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)

        let restoreButton = UIButton.appGray

        view.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(createButton.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        restoreButton.setTitle("welcome.restore_wallet".localized, for: .normal)
        restoreButton.addTarget(self, action: #selector(didTapRestore), for: .touchUpInside)

        view.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(restoreButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin4x)
            maker.centerX.equalToSuperview()
        }

        versionLabel.textColor = .themeGray
        versionLabel.font = .caption

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc func didTapCreate() {
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
