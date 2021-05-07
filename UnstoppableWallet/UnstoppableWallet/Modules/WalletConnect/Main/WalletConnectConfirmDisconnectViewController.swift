import ThemeKit
import ComponentKit

class WalletConnectConfirmDisconnectViewController: ThemeActionSheetController {
    private let remotePeerName: String?
    private let onDisconnect: () -> ()

    private let titleView = BottomSheetTitleView()
    private let disconnectButton = ThemeButton()
    private let cancelButton = ThemeButton()

    init(remotePeerName: String?, onDisconnect: @escaping () -> ()) {
        self.remotePeerName = remotePeerName
        self.onDisconnect = onDisconnect

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "wallet_connect.button_disconnect".localized,
                subtitle: remotePeerName,
                image: UIImage(named: "wallet_connect_24"),
                tintColor: .themeJacob
        )

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(disconnectButton)
        disconnectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        disconnectButton.apply(style: .primaryRed)
        disconnectButton.setTitle("wallet_connect.button_disconnect".localized, for: .normal)
        disconnectButton.addTarget(self, action: #selector(onTapDisconnect), for: .touchUpInside)

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(disconnectButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)
    }

    @objc private func onTapDisconnect() {
        onDisconnect()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

}
