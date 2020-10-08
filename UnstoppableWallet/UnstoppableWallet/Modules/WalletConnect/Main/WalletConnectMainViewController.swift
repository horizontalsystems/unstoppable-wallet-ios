import ThemeKit
import RxSwift
import RxCocoa
import HUD
import SectionsTableView

class WalletConnectMainViewController: ThemeViewController {
    static let spinnerLineWidth: CGFloat = 2
    static let spinnerSideSize: CGFloat = 20

    private let viewModel: WalletConnectViewModel
    private let presenter: WalletConnectMainPresenter
    private weak var sourceViewController: UIViewController?

    private let loadingView = HUDProgressView(strokeLineWidth: WalletConnectMainViewController.spinnerLineWidth,
            radius: WalletConnectMainViewController.spinnerSideSize / 2 - WalletConnectMainViewController.spinnerLineWidth / 2,
            strokeColor: .themeGray)

    private let peerMetaLabel = UILabel()

    private let buttonsHolder = UIView()
    private let cancelButton = ThemeButton()
    private let approveButton = ThemeButton()
    private let rejectButton = ThemeButton()
    private let disconnectButton = ThemeButton()

    private let tableView = SectionsTableView(style: .grouped)

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

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        loadingView.set(hidden: true)

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        buttonsHolder.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        buttonsHolder.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        approveButton.apply(style: .primaryYellow)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        buttonsHolder.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.top.equalTo(approveButton.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        rejectButton.apply(style: .primaryGray)
        rejectButton.setTitle("Reject", for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        buttonsHolder.addSubview(disconnectButton)
        disconnectButton.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        disconnectButton.apply(style: .primaryRed)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.addTarget(self, action: #selector(onTapDisconnect), for: .touchUpInside)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(buttonsHolder.snp.top)
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        presenter.connectingDriver
                .drive(onNext: { [weak self] connecting in
                    self?.sync(connecting: connecting)
                })
                .disposed(by: disposeBag)

        presenter.cancelVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.syncButtons(state: .cancel)
                })
                .disposed(by: disposeBag)

        presenter.approveAndRejectVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.syncButtons(state: .approveReject)
                })
                .disposed(by: disposeBag)

        presenter.disconnectVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.syncButtons(state: .disconnect)
                })
                .disposed(by: disposeBag)

        presenter.closeVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.syncCloseButton(visible: visible)
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

    private func sync(connecting: Bool) {
        loadingView.set(hidden: !connecting)
        if connecting {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
    }

    private func syncButtons(state: ButtonsState) {
        cancelButton.isHidden = true
        approveButton.isHidden = true
        rejectButton.isHidden = true
        disconnectButton.isHidden = true

        switch state {
        case .cancel:
            buttonsHolder.snp.updateConstraints { maker in
                maker.height.equalTo(CGFloat.heightButton)
            }
            cancelButton.isHidden = false
        case .approveReject:
            buttonsHolder.snp.updateConstraints { maker in
                maker.height.equalTo(CGFloat.heightButton * 2 + CGFloat.margin4x)
            }
            approveButton.isHidden = false
            rejectButton.isHidden = false
        case .disconnect:
            buttonsHolder.snp.updateConstraints { maker in
                maker.height.equalTo(CGFloat.heightButton)
            }
            disconnectButton.isHidden = false
        }
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

    @objc private func onTapClose() {
        presenter.close()
    }

    private func syncCloseButton(visible: Bool) {
        if visible {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
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

extension WalletConnectMainViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        []
    }

}

extension WalletConnectMainViewController {
    enum ButtonsState {
        case cancel
        case approveReject
        case disconnect
    }
}
