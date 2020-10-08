import ThemeKit
import RxSwift
import RxCocoa

class WalletConnectMainViewController: ThemeViewController {
    private let viewModel: WalletConnectViewModel
    private let presenter: WalletConnectMainPresenter
    private weak var sourceViewController: UIViewController?

    private let peerMetaLabel = UILabel()
    private let connectingLabel = UILabel()
    private let cancelButton = ThemeButton()
    private let approveButton = ThemeButton()
    private let rejectButton = ThemeButton()
    private let disconnectButton = ThemeButton()

    private let disposeBag = DisposeBag()

    private var peerMeta: WalletConnectMainPresenter.PeerMetaViewItem?
    private var status: WalletConnectMainPresenter.Status?

    init(viewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        presenter = viewModel.mainPresenter
        self.sourceViewController = sourceViewController

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Wallet Connect"

        view.addSubview(peerMetaLabel)
        peerMetaLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin6x)
        }

        peerMetaLabel.numberOfLines = 0
        peerMetaLabel.textColor = .themeRemus

        view.addSubview(connectingLabel)
        connectingLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin6x)
        }

        connectingLabel.text = "Connecting..."
        connectingLabel.textColor = .themeGray

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        view.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        approveButton.apply(style: .primaryYellow)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        view.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(approveButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        rejectButton.apply(style: .primaryGray)
        rejectButton.setTitle("Reject", for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        view.addSubview(disconnectButton)
        disconnectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        disconnectButton.apply(style: .primaryRed)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.addTarget(self, action: #selector(onTapDisconnect), for: .touchUpInside)

        presenter.connectingDriver
                .drive(onNext: { [weak self] connecting in
                    self?.connectingLabel.isHidden = !connecting
                })
                .disposed(by: disposeBag)

        presenter.cancelVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.cancelButton.isHidden = !visible
                })
                .disposed(by: disposeBag)

        presenter.approveAndRejectVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.approveButton.isHidden = !visible
                    self?.rejectButton.isHidden = !visible
                })
                .disposed(by: disposeBag)

        presenter.disconnectVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.disconnectButton.isHidden = !visible
                })
                .disposed(by: disposeBag)

        presenter.signedTransactionsVisibleDriver
                .drive(onNext: { [weak self] visible in
                })
                .disposed(by: disposeBag)

        presenter.peerMetaDriver
                .drive(onNext: { [weak self] peerMeta in
                    self?.peerMeta = peerMeta
                    self?.syncLabel()
                })
                .disposed(by: disposeBag)

        presenter.hintDriver
                .drive(onNext: { [weak self] hint in
                })
                .disposed(by: disposeBag)

        presenter.statusDriver
                .drive(onNext: { [weak self] status in
                    self?.status = status
                    self?.syncLabel()
                })
                .disposed(by: disposeBag)

        presenter.openRequestSignal
                .emit(onNext: { [weak self] id in
                    self?.openRequest(id: id)
                })
                .disposed(by: disposeBag)

        presenter.finishSignal
                .emit(onNext: { [weak self] in
                    self?.sourceViewController?.dismiss(animated: true)
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapCancel() {
        sourceViewController?.dismiss(animated: true)
    }

    @objc private func onTapApprove() {
        presenter.approve()
    }

    @objc private func onTapReject() {
        presenter.reject()
    }

    @objc private func onTapDisconnect() {
        presenter.disconnect()
    }

    private func syncLabel() {
        var textParts = [String]()

        if let peerMeta = peerMeta {
            textParts.append("Name: \(peerMeta.name)")
            textParts.append("Url: \(peerMeta.url)")
            textParts.append("Description: \(peerMeta.description)")
            textParts.append("Icon: \(peerMeta.icon ?? "nil")")
        }

        if let status = status {
            textParts.append("Status: \(status)")
        }

        peerMetaLabel.text = textParts.joined(separator: "\n")
    }

    private func openRequest(id: Int) {
        let viewController = WalletConnectRequestViewController(viewModel: viewModel, requestId: id).toBottomSheet
        present(viewController, animated: true)
    }

}
