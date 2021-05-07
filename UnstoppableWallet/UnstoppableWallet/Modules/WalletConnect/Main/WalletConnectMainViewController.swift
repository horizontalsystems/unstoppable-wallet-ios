import ThemeKit
import RxSwift
import RxCocoa
import UIExtensions
import HUD
import SectionsTableView
import SnapKit
import ComponentKit

class WalletConnectMainViewController: ThemeViewController {
    private let baseViewModel: WalletConnectViewModel
    private let viewModel: WalletConnectMainViewModel
    private weak var sourceViewController: UIViewController?

    private let spinner = HUDActivityView.create(with: .large48)

    private let buttonsHolder = BottomGradientHolder()

    private let disconnectButton = ThemeButton()
    private var disconnectButtonBottomConstraint: Constraint?
    private var disconnectButtonHeightConstraint: Constraint?

    private let connectButton = ThemeButton()
    private var connectButtonBottomConstraint: Constraint?
    private var connectButtonHeightConstraint: Constraint?

    private let cancelButton = ThemeButton()
    private var cancelButtonBottomConstraint: Constraint?
    private var cancelButtonHeightConstraint: Constraint?

    private let tableView = SectionsTableView(style: .grouped)

    private let disposeBag = DisposeBag()

    private var peerMeta: WalletConnectMainViewModel.PeerMetaViewItem?
    private var status: WalletConnectMainViewModel.Status?
    private var hint: String?

    init(baseViewModel: WalletConnectViewModel, sourceViewController: UIViewController?) {
        self.baseViewModel = baseViewModel
        viewModel = baseViewModel.mainViewModel
        self.sourceViewController = sourceViewController

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.title".localized

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.set(hidden: true)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: TermsHeaderCell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: HighlightedDescriptionCell.self)

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin4x)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        buttonsHolder.addSubview(disconnectButton)
        disconnectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)

            disconnectButtonBottomConstraint = maker.bottom.equalToSuperview().offset(-CGFloat.margin4x).constraint
            disconnectButtonHeightConstraint = maker.height.equalTo(CGFloat.heightButton).constraint
        }

        disconnectButton.apply(style: .primaryGray)
        disconnectButton.setTitle("wallet_connect.button_disconnect".localized, for: .normal)
        disconnectButton.addTarget(self, action: #selector(onTapDisconnect), for: .touchUpInside)

        buttonsHolder.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)

            cancelButtonBottomConstraint = maker.bottom.equalTo(disconnectButton.snp.top).offset(-CGFloat.margin4x).constraint
            cancelButtonHeightConstraint = maker.height.equalTo(CGFloat.heightButton).constraint
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        buttonsHolder.addSubview(connectButton)
        connectButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin8x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)

            connectButtonBottomConstraint = maker.bottom.equalTo(cancelButton.snp.top).offset(-CGFloat.margin4x).constraint
            connectButtonHeightConstraint = maker.height.equalTo(CGFloat.heightButton).constraint
        }

        connectButton.apply(style: .primaryYellow)
        connectButton.setTitle("button.connect".localized, for: .normal)
        connectButton.addTarget(self, action: #selector(onTapConnect), for: .touchUpInside)

        viewModel.connectingDriver
                .drive(onNext: { [weak self] connecting in
                    self?.sync(connecting: connecting)
                })
                .disposed(by: disposeBag)

        viewModel.cancelVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.syncButtonConstraints(bottom: self?.cancelButtonBottomConstraint, height: self?.cancelButtonHeightConstraint, visible: visible)
                })
                .disposed(by: disposeBag)

        viewModel.connectButtonDriver
                .drive(onNext: { [weak self] state in
                    self?.syncButtonConstraints(bottom: self?.connectButtonBottomConstraint, height: self?.connectButtonHeightConstraint, visible: state != .hidden)
                    self?.connectButton.isEnabled = state == .enabled
                })
                .disposed(by: disposeBag)

        viewModel.disconnectButtonDriver
                .drive(onNext: { [weak self] state in
                    self?.syncButtonConstraints(bottom: self?.disconnectButtonBottomConstraint, height: self?.disconnectButtonHeightConstraint, visible: state != .hidden)
                    self?.disconnectButton.isEnabled = state == .enabled
                })
                .disposed(by: disposeBag)

        viewModel.closeVisibleDriver
                .drive(onNext: { [weak self] visible in
                    self?.syncCloseButton(visible: visible)
                })
                .disposed(by: disposeBag)

//        viewModel.signedTransactionsVisibleDriver
//                .drive(onNext: { [weak self] visible in
//                })
//                .disposed(by: disposeBag)

        viewModel.peerMetaDriver
                .drive(onNext: { [weak self] peerMeta in
                    self?.peerMeta = peerMeta
                    self?.tableView.reload()
                })
                .disposed(by: disposeBag)

        viewModel.hintDriver
                .drive(onNext: { [weak self] hint in
                    self?.hint = hint
                    self?.tableView.reload()
                })
                .disposed(by: disposeBag)

        viewModel.statusDriver
                .drive(onNext: { [weak self] status in
                    self?.status = status
                    self?.tableView.reload()
                })
                .disposed(by: disposeBag)

        viewModel.openRequestSignal
                .emit(onNext: { [weak self] request in
                    self?.open(request: request)
                })
                .disposed(by: disposeBag)

        viewModel.finishSignal
                .emit(onNext: { [weak self] in
                    self?.sourceViewController?.dismiss(animated: true)
                })
                .disposed(by: disposeBag)
    }

    private func sync(connecting: Bool) {
        spinner.set(hidden: !connecting)
        if connecting {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    private func syncButtonConstraints(bottom: Constraint?, height: Constraint?, visible: Bool) {
        bottom?.update(offset: visible ? -CGFloat.margin4x : 0)
        height?.update(offset: visible ? CGFloat.heightButton : 0)
    }

    @objc private func onTapCancel() {
        viewModel.cancel()
    }

    @objc private func onTapConnect() {
        viewModel.connect()
    }

    @objc private func onTapReject() {
        viewModel.reject()
    }

    @objc private func onTapDisconnect() {
        let viewController = WalletConnectConfirmDisconnectViewController(remotePeerName: peerMeta?.name) { [weak self] in
            self?.viewModel.disconnect()
        }

        present(viewController.toBottomSheet, animated: true)
    }

    @objc private func onTapClose() {
        viewModel.close()
    }

    private func syncCloseButton(visible: Bool) {
        if visible {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func open(request: WalletConnectRequest) {
        var viewController: UIViewController?

        switch request {
        case let request as WalletConnectSendEthereumTransactionRequest:
            viewController = WalletConnectSendEthereumTransactionRequestModule.viewController(baseService: baseViewModel.service, requestId: request.id)
        default: ()
        }

        if let viewController = viewController {
            present(ThemeNavigationController(rootViewController: viewController), animated: true)
        }
    }

}

extension WalletConnectMainViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        if let imageUrl = peerMeta?.icon, let title = peerMeta?.name {
            rows.append(headerRow(imageUrl: imageUrl, title: title))
        }

        if let status = status {
            rows.append(valueRow(title: "status".localized, value: status.title, isFirst: true, isLast: peerMeta == nil, valueColor: status.color))
        }

        if let url = peerMeta?.url {
            rows.append(valueRow(title: "wallet_connect.url".localized, value: url, isFirst: status == nil, isLast: true))
        }

        if let footerRow = footer {
            rows.append(footerRow)
        }

        return [Section(id: "wallet_connect", rows: rows)]
    }

    private var footer: RowProtocol? {
        hint.map { hint -> RowProtocol in
            Row<HighlightedDescriptionCell>(
                    id: "hint_footer",
                    dynamicHeight: { width in
                        HighlightedDescriptionCell.height(containerWidth: width, text: hint)
                    },
                    bind: { cell, _ in
                        cell.descriptionText = hint
                    }
            )
        }
    }

    private func headerRow(imageUrl: String?, title: String) -> RowProtocol {
        Row<TermsHeaderCell>(id: "header", height: TermsHeaderCell.height, bind: { cell, _ in
            cell.bind(imageUrl: imageUrl, title: title, subtitle: nil)
        })
    }

    private func valueRow(title: String, value: String, isFirst: Bool, isLast: Bool, valueColor: UIColor? = nil) -> RowProtocol {
        Row<D7Cell>(
                id: "row_\(title)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = valueColor ?? .themeLeah
                }
        )
    }

}
