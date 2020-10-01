import ThemeKit

class WalletConnectErrorViewController: ThemeViewController {
    private let baseView: WalletConnectView
    private let error: Error

    private let closeButton = ThemeButton()

    init(baseView: WalletConnectView, error: Error) {
        self.baseView = baseView
        self.error = error

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Wallet Connect"

        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        closeButton.apply(style: .primaryGray)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
    }

    @objc private func onClose() {
        baseView.viewModel.onFinish()
    }

}
