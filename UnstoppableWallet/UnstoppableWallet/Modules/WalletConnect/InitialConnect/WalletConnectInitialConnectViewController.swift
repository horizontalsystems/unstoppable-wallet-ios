import ThemeKit

class WalletConnectInitialConnectViewController: ThemeViewController {
    private let baseView: WalletConnectView
    private let viewModel: WalletConnectInitialConnectViewModel

    private let connectButton = ThemeButton()
    private let cancelButton = ThemeButton()

    init?(baseView: WalletConnectView, viewModel: WalletConnectInitialConnectViewModel) {
        self.baseView = baseView
        self.viewModel = viewModel

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Wallet Connect"

        view.addSubview(connectButton)
        connectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        connectButton.apply(style: .primaryYellow)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.addTarget(self, action: #selector(onConnect), for: .touchUpInside)

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(connectButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
    }

    @objc private func onConnect() {
    }

    @objc private func onCancel() {
        baseView.viewModel.onFinish()
    }

}
