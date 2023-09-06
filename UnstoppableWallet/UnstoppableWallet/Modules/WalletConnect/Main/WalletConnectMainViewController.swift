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
    private let disposeBag = DisposeBag()
    private var pendingRequestDisposeBag = DisposeBag()

    private weak var sourceViewController: UIViewController?

    var pendingRequestViewModel: WalletConnectMainPendingRequestViewModel? {
        didSet {
            pendingRequestDisposeBag = DisposeBag()
            if let viewModel = pendingRequestViewModel {
                subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in
                    self?.sync(pendingRequestViewItems: $0)
                }
                subscribe(disposeBag, viewModel.showPendingRequestSignal) { [weak self] in
                    self?.showPending(request: $0)
                }
            }
        }
    }
    private var pendingRequestViewItems = [WalletConnectMainPendingRequestViewModel.ViewItem]()

    private let spinner = HUDActivityView.create(with: .large48)
    private let buttonsHolder = BottomGradientHolder()
    private let disconnectButton = PrimaryButton()
    private let connectButton = PrimaryButton()
    private let reconnectButton = PrimaryButton()
    private let cancelButton = PrimaryButton()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItem: WalletConnectMainViewModel.ViewItem?

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

        buttonsHolder.add(to: self, under: tableView)
        buttonsHolder.addSubview(connectButton)

        connectButton.set(style: .yellow)
        connectButton.setTitle("button.connect".localized, for: .normal)
        connectButton.addTarget(self, action: #selector(onTapConnect), for: .touchUpInside)

        buttonsHolder.addSubview(reconnectButton)

        reconnectButton.set(style: .yellow)
        reconnectButton.setTitle("wallet_connect.button_reconnect".localized, for: .normal)
        reconnectButton.addTarget(self, action: #selector(onTapReconnect), for: .touchUpInside)

        buttonsHolder.addSubview(cancelButton)

        cancelButton.set(style: .gray)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        buttonsHolder.addSubview(disconnectButton)

        disconnectButton.set(style: .red)
        disconnectButton.setTitle("wallet_connect.button_disconnect".localized, for: .normal)
        disconnectButton.addTarget(self, action: #selector(onTapDisconnect), for: .touchUpInside)

        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in
            self?.show(error: $0)
        }
        subscribe(disposeBag, viewModel.showSuccessSignal) {
            HudHelper.instance.show(banner: .done)
        }
        subscribe(disposeBag, viewModel.showDisconnectSignal) {
            HudHelper.instance.show(banner: .disconnectedWalletConnect)
        }
        subscribe(disposeBag, viewModel.showTimeOutAttentionSignal) {
            HudHelper.instance.show(banner: .error(string: "alert.try_again".localized))
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
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in
            self?.viewItem = $0
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.close()
        }

        tableView.buildSections()
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

    private func openSelectNetwork() {
        let viewItems = viewModel.blockchainSelectorViewItems

        let selectorViewItems = viewItems.map {
            SelectorModule.ViewItem(
                    image: .url($0.imageUrl, placeholder: "placeholder_rectangle_32"),
                    title: $0.title,
                    selected: $0.selected
            )
        }

        let viewController = SelectorModule.bottomSingleSelectorViewController(
                image: .local(image: UIImage(named: "blocks_24")?.withTintColor(.themeJacob)),
                title: "wallet_connect.network".localized,
                viewItems: selectorViewItems,
                onSelect: { [weak self] index in
                    self?.viewModel.onSelect(chainId: viewItems[index].chainId)
                }
        )

        DispatchQueue.main.async {
            self.present(viewController, animated: true)
        }
    }

    // pending requests section

    private func sync(pendingRequestViewItems: [WalletConnectMainPendingRequestViewModel.ViewItem]) {
        self.pendingRequestViewItems = pendingRequestViewItems

        tableView.reload()
    }

    private func onSelect(requestId: Int) {
        pendingRequestViewModel?.onSelect(requestId: requestId)
    }

    private func onTapReject(pendingRequestViewItem: WalletConnectMainPendingRequestViewModel.ViewItem) {
        pendingRequestViewModel?.onReject(id: pendingRequestViewItem.id)
    }

    private func showPending(request: WalletConnectRequest) {
        guard let viewController = WalletConnectRequestModule.viewController(signService: App.shared.walletConnectSessionManager.service, request: request) else {
            return
        }

        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }


}

extension WalletConnectMainViewController: SectionsDataSource {

    private func pendingRequestCell(viewItem: WalletConnectMainPendingRequestViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        var elements: [CellBuilderNew.CellElement] = [
            .vStackCentered([
                .text { component in
                    component.font = .body
                    component.textColor = .themeLeah
                    component.text = viewItem.title
                },
                .margin(1),
                .text { component in
                    component.font = .subhead2
                    component.textColor = .themeGray
                    component.lineBreakMode = .byTruncatingMiddle
                    component.text = viewItem.subtitle
                }
            ])
        ]

        if viewItem.unsupported {
            elements.append(.secondaryButton { component in
                component.button.set(style: .default)
                component.button.setTitle("Reject", for: .normal)
                component.button.setTitleColor(.themeLucian, for: .normal)
                component.onTap = { [weak self] in
                    self?.onTapReject(pendingRequestViewItem: viewItem)
                }
            })
        } else {
            elements.append(.image20 { component in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")
            })
        }

        return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: "request_item_\(viewItem.id)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: { [weak self] in self?.onSelect(requestId: viewItem.id) }
        )
    }

    private func pendingRequestSection() -> SectionProtocol? {
        guard !pendingRequestViewItems.isEmpty else {
            return nil
        }
        return Section(id: "pending-requests",
                headerState: tableView.sectionHeader(text: "wallet_connect.list.pending_requests".localized),
                footerState: .margin(height: .margin32),
                rows: pendingRequestViewItems.enumerated().map { index, viewItem in
                    pendingRequestCell(viewItem: viewItem, isFirst: index == 0, isLast: index == pendingRequestViewItems.count - 1)
                }
        )
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

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()

        if let viewItem = viewItem {
            if let dAppMeta = viewItem.dAppMeta {
                sections.append(Section(id: "dapp-meta",
                        rows: [headerRow(imageUrl: dAppMeta.icon, title: dAppMeta.name)]))
            }

            if let pendingRequestSection = pendingRequestSection() {
                sections.append(pendingRequestSection)
            }

            var rowInfos = [RowInfo]()

            if let status = viewItem.status {
                rowInfos.append(.value(title: "status".localized, value: status.title, valueColor: status.color))
            }

            if let dAppMeta = viewItem.dAppMeta {
                rowInfos.append(.value(title: "wallet_connect.url".localized, value: dAppMeta.url, valueColor: nil))
            }

            if let accountName = viewItem.activeAccountName {
                rowInfos.append(.value(title: "wallet_connect.active_account".localized, value: accountName, valueColor: nil))
            }

            if viewItem.networkEditable {
                if let address = viewItem.address {
                    rowInfos.append(.value(title: "wallet_connect.address".localized, value: address, valueColor: nil))
                }

                if let network = viewItem.network {
                    rowInfos.append(.network(value: network, editable: true))
                }
            } else {
                if let network = viewItem.network, let address = viewItem.address {
                    rowInfos.append(.value(title: network, value: address, valueColor: nil))
                }
            }

            for (index, rowInfo) in rowInfos.enumerated() {
                let isFirst = index == 0
                let isLast = index == rowInfos.count - 1

                switch rowInfo {
                case let .value(title, value, valueColor):
                    rows.append(tableView.universalRow48(
                            id: "value-\(index)",
                            title: .subhead2(title),
                            value: .subhead1(value, color: valueColor ?? .themeLeah),
                            hash: value,
                            isFirst: isFirst,
                            isLast: isLast
                    ))
                case let .network(value, editable):
                    let row = tableView.universalRow48(
                            id: "network-\(index)",
                            title: .subhead2("wallet_connect.network".localized),
                            value: .subhead1(value),
                            accessoryType: .dropdown,
                            hash: value,
                            autoDeselect: true,
                            isFirst: isFirst,
                            isLast: isLast,
                            action: editable ? { [weak self] in
                                self?.openSelectNetwork()
                            } : nil
                    )
                    rows.append(row)
                case let .chain(title, value, selected, chainId):
                    let row = tableView.universalRow48(
                            id: "chain-\(index)",
                            image: .local(selected ? UIImage(named: "checkbox_active_24") : UIImage(named: "checkbox_diactive_24")),
                            title: .subhead2(title),
                            value: .subhead1(value),
                            hash: "\(selected)",
                            autoDeselect: true,
                            isFirst: isFirst,
                            isLast: isLast,
                            action: { [weak self] in
                                self?.viewModel.onToggle(chainId: chainId)
                            }
                    )

                    rows.append(row)
                }
            }

            if let hint = viewItem.hint {
                rows.append(tableView.highlightedDescriptionRow(id: "hint_footer", text: hint))
            }
        }

        sections.append(Section(id: "wallet_connect", rows: rows))
        return sections
    }

}

extension WalletConnectMainViewController {

    enum RowInfo {
        case value(title: String, value: String, valueColor: UIColor?)
        case network(value: String, editable: Bool)
        case chain(title: String, value: String, selected: Bool, chainId: Int)
    }

}
