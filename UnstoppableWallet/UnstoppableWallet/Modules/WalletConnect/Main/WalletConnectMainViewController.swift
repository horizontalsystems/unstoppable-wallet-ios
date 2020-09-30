import ThemeKit

class WalletConnectMainViewController: ThemeViewController {
    weak var sourceViewController: UIViewController?

    private let baseViewModel: WalletConnectViewModel
    private let viewModel: WalletConnectMainViewModel

    private let disconnectButton = ThemeButton()

    init(baseViewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.baseViewModel = baseViewModel
        self.sourceViewController = sourceViewController

        viewModel = baseViewModel.mainViewModel

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Wallet Connect"

        view.addSubview(disconnectButton)
        disconnectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        disconnectButton.apply(style: .primaryRed)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.addTarget(self, action: #selector(onDisconnect), for: .touchUpInside)
    }

    @objc private func onDisconnect() {
        sourceViewController?.dismiss(animated: true)
    }

}
