import ThemeKit

class WalletConnectInitialConnectViewController: ThemeViewController {
    weak var sourceViewController: UIViewController?

    private let baseViewModel: WalletConnectViewModel
    private let viewModel: WalletConnectInitialConnectViewModel

    private let connectButton = ThemeButton()
    private let cancelButton = ThemeButton()

    init(baseViewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.baseViewModel = baseViewModel
        self.sourceViewController = sourceViewController

        viewModel = baseViewModel.initialConnectViewModel

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
        let viewController = WalletConnectMainViewController(baseViewModel: baseViewModel, sourceViewController: sourceViewController)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    @objc private func onCancel() {
        sourceViewController?.dismiss(animated: true)
    }

}
