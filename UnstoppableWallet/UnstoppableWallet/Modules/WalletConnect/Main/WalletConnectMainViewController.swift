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

    private let disconnectButton = PrimaryButton()
    private let connectButton = PrimaryButton()
    private let reconnectButton = PrimaryButton()
    private let cancelButton = PrimaryButton()

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

        tableView.registerCell(forClass: LogoHeaderCell.self)

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

        let stackView = UIStackView()

        buttonsHolder.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.bottom.equalToSuperview().offset(-CGFloat.margin16)
        }

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = .margin16

        stackView.addArrangedSubview(connectButton)

        connectButton.set(style: .yellow)
        connectButton.setTitle("button.connect".localized, for: .normal)
        connectButton.addTarget(self, action: #selector(onTapConnect), for: .touchUpInside)

        stackView.addArrangedSubview(reconnectButton)

        reconnectButton.set(style: .yellow)
        reconnectButton.setTitle("wallet_connect.button_reconnect".localized, for: .normal)
        reconnectButton.addTarget(self, action: #selector(onTapReconnect), for: .touchUpInside)

        stackView.addArrangedSubview(cancelButton)

        cancelButton.set(style: .gray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        stackView.addArrangedSubview(disconnectButton)

        disconnectButton.set(style: .red)
        disconnectButton.setTitle("wallet_connect.button_disconnect".localized, for: .normal)
        disconnectButton.addTarget(self, action: #selector(onTapDisconnect), for: .touchUpInside)

        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in
            self?.show(error: $0)
        }
        subscribe(disposeBag, viewModel.showSuccessSignal) {
            HudHelper.instance.show(banner: .success)
        }
        subscribe(disposeBag, viewModel.showDisconnectSignal) {
            HudHelper.instance.show(banner: .disconnectedWalletConnect)
        }
        subscribe(disposeBag, viewModel.connectingDriver) { [weak self] in
            self?.sync(connecting: $0)
        }
        subscribe(disposeBag, viewModel.cancelVisibleDriver) { [weak self] in
            self?.cancelButton.isHidden = !$0
        }
        subscribe(disposeBag, viewModel.connectButtonDriver) { [weak self] state in
            self?.connectButton.isHidden = state == .hidden
            self?.connectButton.isEnabled = state == .enabled
        }
        subscribe(disposeBag, viewModel.reconnectButtonDriver) { [weak self] state in
            self?.reconnectButton.isHidden = state == .hidden
            self?.reconnectButton.isEnabled = state == .enabled
        }
        subscribe(disposeBag, viewModel.disconnectButtonDriver) { [weak self] state in
            self?.isModalInPresentation = state != .enabled
            self?.disconnectButton.isHidden = state == .hidden
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
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func sync(connecting: Bool) {
        spinner.set(hidden: !connecting)
        if connecting {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
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
            tableView.highlightedDescriptionRow(id: "hint_footer", text: hint)
        }
    }

    private func headerRow(imageUrl: String?, title: String) -> RowProtocol {
        Row<LogoHeaderCell>(
                id: "header",
                hash: "\(title)-\(imageUrl ?? "N/A")",
                height: LogoHeaderCell.height,
                bind: { cell, _ in
                    cell.title = title
                    cell.set(imageUrl: imageUrl)
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
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    })
                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.font = .subhead1
                        component.textColor = .themeLeah
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
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    })
                    cell.bind(index: 2, block: { (component: TextComponent) in
                        component.font = .subhead1
                        component.textColor = .themeLeah
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
