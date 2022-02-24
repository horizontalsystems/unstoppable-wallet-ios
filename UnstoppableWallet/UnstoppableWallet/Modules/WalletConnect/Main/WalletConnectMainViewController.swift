import UIKit
import ThemeKit
import RxSwift
import RxCocoa
import UIExtensions
import HUD
import SectionsTableView
import SnapKit
import ComponentKit

class WalletConnectMainViewController: ThemeViewController {
    private let viewModel: WalletConnectMainViewModel
    private weak var sourceViewController: UIViewController?
    var requestView: IWalletConnectMainRequestView?

    private let spinner = HUDActivityView.create(with: .large48)

    private let buttonsHolder = BottomGradientHolder()

    private let disconnectButton = ThemeButton()
    private var disconnectButtonBottomConstraint: Constraint?
    private var disconnectButtonHeightConstraint: Constraint?

    private let connectButton = ThemeButton()
    private var connectButtonBottomConstraint: Constraint?
    private var connectButtonHeightConstraint: Constraint?

    private let reconnectButton = ThemeButton()
    private var reconnectButtonBottomConstraint: Constraint?
    private var reconnectButtonHeightConstraint: Constraint?

    private let cancelButton = ThemeButton()
    private var cancelButtonBottomConstraint: Constraint?
    private var cancelButtonHeightConstraint: Constraint?

    private let tableView = SectionsTableView(style: .grouped)

    private let disposeBag = DisposeBag()

    private var activeAccountName: String?
    private var appMeta: WalletConnectMainViewModel.AppMetaViewItem?
    private var blockchainEditable: Bool = false
    private var blockchains: [WalletConnectMainViewModel.BlockchainViewItem]?
    private var status: WalletConnectMainViewModel.Status?
    private var hint: String?

    init(viewModel: WalletConnectMainViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: TermsHeaderCell.self)
        tableView.registerCell(forClass: HighlightedDescriptionCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.set(hidden: true)

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

        disconnectButton.apply(style: .primaryRed)
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

        buttonsHolder.addSubview(reconnectButton)
        reconnectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)

            reconnectButtonBottomConstraint = maker.bottom.equalTo(cancelButton.snp.top).offset(-CGFloat.margin4x).constraint
            reconnectButtonHeightConstraint = maker.height.equalTo(CGFloat.heightButton).constraint
        }

        reconnectButton.apply(style: .primaryYellow)
        reconnectButton.setTitle("wallet_connect.button_reconnect".localized, for: .normal)
        reconnectButton.addTarget(self, action: #selector(onTapReconnect), for: .touchUpInside)

        buttonsHolder.addSubview(connectButton)
        connectButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin8x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)

            connectButtonBottomConstraint = maker.bottom.equalTo(reconnectButton.snp.top).offset(-CGFloat.margin4x).constraint
            connectButtonHeightConstraint = maker.height.equalTo(CGFloat.heightButton).constraint
        }

        connectButton.apply(style: .primaryYellow)
        connectButton.setTitle("button.connect".localized, for: .normal)
        connectButton.addTarget(self, action: #selector(onTapConnect), for: .touchUpInside)

        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in
            self?.show(error: $0)
        }
        subscribe(disposeBag, viewModel.showSuccessSignal) {
            HudHelper.instance.showSuccess(title: "alert.success_action".localized)
        }
        subscribe(disposeBag, viewModel.connectingDriver) { [weak self] in
            self?.sync(connecting: $0)
        }
        subscribe(disposeBag, viewModel.cancelVisibleDriver) { [weak self] in
            self?.syncButtonConstraints(bottom: self?.cancelButtonBottomConstraint, height: self?.cancelButtonHeightConstraint, visible: $0)
        }
        subscribe(disposeBag, viewModel.connectButtonDriver) { [weak self] state in
            self?.syncButtonConstraints(bottom: self?.connectButtonBottomConstraint, height: self?.connectButtonHeightConstraint, visible: state != .hidden)
            self?.connectButton.isEnabled = state == .enabled
        }
        subscribe(disposeBag, viewModel.reconnectButtonDriver) { [weak self] state in
            self?.syncButtonConstraints(bottom: self?.reconnectButtonBottomConstraint, height: self?.reconnectButtonHeightConstraint, visible: state != .hidden)
            self?.reconnectButton.isEnabled = state == .enabled
        }
        subscribe(disposeBag, viewModel.disconnectButtonDriver) { [weak self] state in
            self?.isModalInPresentation = state != .enabled
            self?.syncButtonConstraints(bottom: self?.disconnectButtonBottomConstraint, height: self?.disconnectButtonHeightConstraint, visible: state != .hidden)
            self?.disconnectButton.isEnabled = state == .enabled
        }
        subscribe(disposeBag, viewModel.closeVisibleDriver) { [weak self] in
            self?.syncCloseButton(visible: $0)
        }
        subscribe(disposeBag, viewModel.activeAccountNameDriver) { [weak self] in
            self?.activeAccountName = $0
        }
        subscribe(disposeBag, viewModel.appMetaDriver) { [weak self] in
            self?.appMeta = $0
        }
        subscribe(disposeBag, viewModel.blockchainsEditableDriver) { [weak self] in
            self?.blockchainEditable = $0
        }
        subscribe(disposeBag, viewModel.blockchainViewItemDriver) { [weak self] in
            self?.blockchains = $0
        }
        subscribe(disposeBag, viewModel.hintDriver) { [weak self] in
            self?.hint = $0
        }
        subscribe(disposeBag, viewModel.statusDriver) { [weak self] in
            self?.status = $0
        }
        subscribe(disposeBag, viewModel.reloadTableSignal) { [weak self] in
            self?.tableView.reload(animated: true)
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.close()
        }

        tableView.reload()
    }

    private func show(error: String) {
        HudHelper.instance.showError(title: error)
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
        viewModel.disconnect()
    }

    @objc private func onTapReconnect() {
        viewModel.reconnect()
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

    private func close() {
        sourceViewController?.dismiss(animated: true)
    }

    private var footer: RowProtocol? {
        hint.map { hint -> RowProtocol in
            Row<HighlightedDescriptionCell>(
                    id: "hint_footer",
                    hash: hint,
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
        Row<TermsHeaderCell>(
                id: "header",
                hash: "\(title)-\(imageUrl ?? "N/A")",
                height: TermsHeaderCell.height,
                bind: { cell, _ in
                    cell.bind(imageUrl: imageUrl, title: title, subtitle: nil)
                }
        )
    }

    private func valueRow(title: String, value: String, isFirst: Bool, isLast: Bool, valueColor: UIColor? = nil) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .text],
                tableView: tableView,
                id: "non-selectable-row-\(title)",
                hash: "non-selectable-\(title)-\(value)-\(isFirst.description)-\(isLast.description)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.bind(index: 0, block: { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = title
                    })
                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.set(style: .c2)
                        component.text = value
                        if let color = valueColor {
                            component.textColor = color
                        }
                    })
                })
    }

    private func selectableValueRow(title: String, value: String, selected: Bool, isFirst: Bool, isLast: Bool, valueColor: UIColor? = nil, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .text, .text],
                tableView: tableView,
                id: "selectable-row-\(title)",
                hash: "selectable-\(title)-\(value)-\(selected.description)-\(isFirst.description)-\(isLast.description)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = selected ? UIImage(named: "checkbox_active_24") : UIImage(named: "checkbox_diactive_24")
                    })
                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = title
                    })
                    cell.bind(index: 2, block: { (component: TextComponent) in
                        component.set(style: .c2)
                        component.text = value
                        if let color = valueColor {
                            component.textColor = color
                        }
                    })
                },
                action: action)
    }

}

extension WalletConnectMainViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        guard let appMeta = appMeta else {
            return [Section(id: "wallet_connect", rows: rows)]
        }

        if let imageUrl = appMeta.icon {
            rows.append(headerRow(imageUrl: imageUrl, title: appMeta.name))
        }

        if let status = status {
            rows.append(valueRow(title: "status".localized, value: status.title, isFirst: true, isLast: activeAccountName == nil, valueColor: status.color))
        }

        rows.append(valueRow(title: "wallet_connect.url".localized, value: appMeta.url, isFirst: status == nil, isLast: activeAccountName == nil))

        if let accountName = activeAccountName {
            rows.append(valueRow(title: "wallet_connect.active_account".localized, value: accountName, isFirst: status == nil, isLast: (blockchains ?? []).isEmpty))
        }

        if let blockchains = blockchains, !blockchains.isEmpty {
            rows.append(contentsOf: blockchains
                    .enumerated()
                    .map { index, blockchain in
                        if blockchainEditable {
                            return selectableValueRow(
                                    title: blockchain.chainTitle ?? "Unsupported",
                                    value: blockchain.address,
                                    selected: blockchain.selected,
                                    isFirst: false,
                                    isLast: index == blockchains.count - 1,
                                    action: { [weak self] in
                                        self?.viewModel.onToggle(chainId: blockchain.chainId)
                                    }
                            )
                        } else {
                            return valueRow(
                                    title: blockchain.chainTitle ?? "Unsupported",
                                    value: blockchain.address,
                                    isFirst: false,
                                    isLast: index == blockchains.count - 1
                            )
                        }
                    })
        }

        if let footerRow = footer {
            rows.append(footerRow)
        }

        return [Section(id: "wallet_connect", rows: rows)]
    }

}
