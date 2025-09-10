import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import SwiftUI
import UIExtensions
import UIKit

class WalletConnectMainViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private var pendingRequestDisposeBag = DisposeBag()

    private let viewModel: WalletConnectMainViewModel
    private let requestViewFactory: IWalletConnectRequestViewFactory

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

    private let viaPushing: Bool
    private let tableView = SectionsTableView(style: .grouped)

    private var viewItem: WalletConnectMainViewModel.ViewItem?
    private var headerState: WalletConnectMainViewModel.TitleState = .connect
    private var whitelistState: WalletConnectMainModule.WhitelistState = .loading

    init(viewModel: WalletConnectMainViewModel, requestViewFactory: IWalletConnectRequestViewFactory, sourceViewController: UIViewController?, viaPushing: Bool = false) {
        self.viewModel = viewModel
        self.requestViewFactory = requestViewFactory
        self.sourceViewController = sourceViewController
        self.viaPushing = viaPushing

        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
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
        tableView.registerCell(forClass: PremiumAlertCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.set(hidden: true)

        buttonsHolder.add(to: self, under: tableView)
        buttonsHolder.addSubview(connectButton)

        connectButton.set(style: .gray)
        connectButton.setTitle("button.connect".localized, for: .normal)
        connectButton.addTarget(self, action: #selector(onTapConnect), for: .touchUpInside)

        buttonsHolder.addSubview(reconnectButton)

        reconnectButton.set(style: .yellow)
        reconnectButton.setTitle("wallet_connect.button_reconnect".localized, for: .normal)
        reconnectButton.addTarget(self, action: #selector(onTapReconnect), for: .touchUpInside)

        buttonsHolder.addSubview(cancelButton)

        cancelButton.set(style: .transparent)
        cancelButton.setTitle("button.cancel".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)

        buttonsHolder.addSubview(disconnectButton)

        disconnectButton.set(style: .gray)
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
        subscribe(disposeBag, viewModel.headerTitleStateDriver) { [weak self] state in
            self?.headerState = state
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.whitelistStateDriver) { [weak self] state in
            self?.whitelistState = state
            self?.tableView.reload()
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
        stat(page: .walletConnectSession, event: .cancel)
        viewModel.cancel()
    }

    @objc private func onTapConnect() {
        stat(page: .walletConnectSession, event: .connect)
        viewModel.connect()
    }

    @objc private func onTapReject() {
        stat(page: .walletConnectSession, event: .reject)
        viewModel.reject()
    }

    @objc private func onTapDisconnect() {
        stat(page: .walletConnectSession, event: .disconnect)
        viewModel.disconnect()
    }

    @objc private func onTapReconnect() {
        stat(page: .walletConnectSession, event: .reconnect)
        viewModel.reconnect()
    }

    @objc private func onTapClose() {
        viewModel.close()
    }

    private func syncCloseButton(visible: Bool) {
        if visible, !viaPushing {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func close() {
        if viaPushing {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
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
        let result = requestViewFactory.viewController(request: request)
        switch result {
        case .unsuccessful:
            print("Can't create view")
            return
        case let .controller(controller):
            guard let controller else { return }
            stat(page: .walletConnectSession, event: .open(page: .walletConnectRequest))
            present(controller, animated: true)
        }
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
                },
            ]),
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

    private func pendingRequestSection(hasBottomMargin: Bool) -> SectionProtocol? {
        guard !pendingRequestViewItems.isEmpty else {
            return nil
        }
        return Section(id: "pending-requests",
                       headerState: tableView.sectionHeader(text: "wallet_connect.list.pending_requests".localized),
                       footerState: .margin(height: hasBottomMargin ? .margin16 : 0),
                       rows: pendingRequestViewItems.enumerated().map { index, viewItem in
                           pendingRequestCell(viewItem: viewItem, isFirst: index == 0, isLast: index == pendingRequestViewItems.count - 1)
                       })
    }

    private func headerRow(imageUrl: String?, title: String, url: String) -> RowProtocol {
        Row<LogoHeaderCell>(
            id: "header",
            hash: "\(title)-\(imageUrl ?? "N/A")",
            dynamicHeight: { width in
                LogoHeaderCell.height(title: title, url: url, width: width)
            },
            bind: { cell, _ in
                cell.title = title
                cell.subtitle = url
                cell.set(imageUrl: imageUrl)
            }
        )
    }

    private func premiumAlertRow() -> RowProtocol? {
        guard whitelistState.showAlert else {
            return nil
        }

        let state = whitelistState

        return Row<PremiumAlertCell>(
            id: "premium-alert",
            hash: "premium-alert-\(whitelistState.rawValue)",
            dynamicHeight: { width in
                PremiumAlertCell.height(title: state.alertTitle, subtitle: state.alertSubtitle, width: width)
            },
            bind: { cell, _ in
                cell.setTitle(title: state.alertTitle, color: state.alertTitleColor)
                cell.subtitle = state.alertSubtitle
                cell.setIcon(name: state.alertIcon, color: state.alertTitleColor)
                cell.setBorder(color: state.alertTitleColor)
            }
        )
    }

    private func row(info: RowInfo, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        switch info {
        case let .value(title, value, valueColor):
            return tableView.universalRow48(
                id: "value-\(index)",
                title: .subhead2(title),
                value: .subhead1(value, color: valueColor ?? .themeLeah),
                hash: value,
                isFirst: isFirst,
                isLast: isLast
            )
        case let .scam(state):
            var elements = [CellBuilderNew.CellElement]()
            elements.append(.textElement(text: .subhead2("wallet_connect.scam_protection".localized)))
            if let value = state.protectionValue {
                elements.append(.textElement(text: .subhead1(value, color: state.protectionValueColor), parameters: .allCompression))
            }
            if let icon = state.protectionIcon {
                elements.append(.margin12)
                elements.append(
                    .image20 { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: icon)
                        component.imageView.tintColor = state.protectionValueColor
                    }
                )
            }
            if state == .loading {
                elements.append(.spinner20 { _ in
                    ()
                })
            }

            var action: (() -> Void)?
            if !viewModel.premiumEnabled {
                action = {
                    Coordinator.shared.presentPurchase(page: .aboutApp, trigger: .priceCloseTo)
                }
            }

            return CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: "value-\(index)",
                hash: state.rawValue,
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: action,
            )
        case let .blockchains(blockchains):
            let onlyOne = blockchains.count == 1
            let accessory: CellBuilderNew.CellElement.AccessoryType = onlyOne ? .none : .dropdown
            let value = onlyOne ? blockchains[0].blockchain.name : "\(blockchains.count)"

            var action: (() -> Void)?
            if !onlyOne {
                let blockchains = blockchains.map(\.blockchain)
                action = { [weak self] in
                    let blockchainViewController = BlockchainListView(blockchains: blockchains).toNavigationViewController()
                    self?.present(blockchainViewController, animated: true)
                }
            }

            return tableView.universalRow48(
                id: "value-\(index)",
                title: .subhead2("wallet_connect.networks".localized),
                value: .subhead1(value),
                accessoryType: accessory,
                hash: "\(blockchains.count)",
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: action
            )
        }
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()

        if let viewItem {
            if let dAppMeta = viewItem.dAppMeta {
                sections.append(Section(id: "dapp-meta",
                                        rows: [headerRow(imageUrl: dAppMeta.icon, title: headerState.title(name: dAppMeta.name), url: dAppMeta.url)]))
            }

            let premiumRow = premiumAlertRow()
            if let pendingRequestSection = pendingRequestSection(hasBottomMargin: premiumRow == nil) {
                sections.append(pendingRequestSection)
            }

            if let row = premiumRow {
                sections.append(Section(id: "premium-alert", rows: [row]))
            }

            var rowInfos = [RowInfo]()

            rowInfos.append(.scam(whitelistState))

            if let accountName = viewItem.activeAccountName {
                rowInfos.append(.value(title: "wallet_connect.active_account".localized, value: accountName, valueColor: nil))
            }

            let noBlockchainCell = viewItem.blockchains.map(\.isEmpty) ?? true
            for (index, rowInfo) in rowInfos.enumerated() {
                let isFirst = index == 0
                let isLast = noBlockchainCell ? (index == rowInfos.count - 1) : false

                rows.append(row(info: rowInfo, index: index, isFirst: isFirst, isLast: isLast))
            }

            if let blockchains = viewItem.blockchains, !blockchains.isEmpty {
                rows.append(row(info: .blockchains(blockchains), index: rows.count, isFirst: false, isLast: true))
            }

            if let hint = viewItem.hint {
                rows.append(tableView.descriptionRow(id: "hint_footer", text: hint, font: .subhead1, textColor: .gray))
            }
        }

        sections.append(Section(id: "wallet_connect", rows: rows))
        return sections
    }
}

extension WalletConnectMainViewController {
    enum RowInfo {
        case value(title: String, value: String, valueColor: UIColor?)
        case scam(WalletConnectMainModule.WhitelistState)
        case blockchains([WalletConnectMainViewModel.BlockchainViewItem])
    }
}
