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

    private weak var sourceViewController: UIViewController?

    var requestView: IWalletConnectMainRequestView?

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
            HudHelper.instance.show(banner: .done)
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
        let titleViewItem = BottomSheetItem.ComplexTitleViewItem(
                title: "wallet_connect.network".localized,
                image: UIImage(named: "blocks_24")?.withTintColor(.themeJacob)
        )

        let viewItems = viewModel.blockchainSelectorViewItems

        let items = viewItems.map {
            ItemSelectorModule.Item.simple(
                    viewItem: BottomSheetItem.SimpleViewItem(
                            imageUrl: $0.imageUrl,
                            title: $0.title,
                            selected: $0.selected
                    )
            )
        }

        let itemSelector = ItemSelectorModule.viewController(title: .complex(viewItem: titleViewItem), items: items, onTap: { [weak self] selector, index in
            selector.dismiss(animated: true)
            self?.viewModel.onSelect(chainId: viewItems[index].chainId)
        })

        DispatchQueue.main.async {
            self.present(itemSelector.toBottomSheet, animated: true)
        }
    }

}

extension WalletConnectMainViewController: SectionsDataSource {

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
        var rows = [RowProtocol]()

        if let viewItem = viewItem {
            if let dAppMeta = viewItem.dAppMeta {
                rows.append(headerRow(imageUrl: dAppMeta.icon, title: dAppMeta.name))
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

            if let address = viewItem.address {
                rowInfos.append(.value(title: "wallet_connect.address".localized, value: address, valueColor: nil))
            }

            if let network = viewItem.network {
                rowInfos.append(.network(value: network, editable: viewItem.networkEditable))
            }

            if let blockchains = viewItem.blockchains {
                for blockchain in blockchains {
                    rowInfos.append(.chain(
                            title: blockchain.chainTitle ?? "Unsupported",
                            value: blockchain.address,
                            selected: blockchain.selected,
                            chainId: blockchain.chainId
                    ))
                }
            }

            for (index, rowInfo) in rowInfos.enumerated() {
                let isFirst = index == 0
                let isLast = index == rowInfos.count - 1

                switch rowInfo {
                case let .value(title, value, valueColor):
                    rows.append(tableView.grayTitleWithValueRow(
                            id: "value-\(index)",
                            hash: value,
                            title: title,
                            value: value,
                            valueColor: valueColor ?? .themeLeah,
                            isFirst: isFirst,
                            isLast: isLast
                    ))
                case let .network(value, editable):
                    let row = CellBuilderNew.row(
                            rootElement: .hStack([
                                .text { component in
                                    component.font = .subhead2
                                    component.textColor = .themeGray
                                    component.text = "wallet_connect.network".localized
                                },
                                .text { component in
                                    component.font = .subhead1
                                    component.textColor = .themeLeah
                                    component.text = value
                                },
                                .margin8,
                                .image20 { component in
                                    component.isHidden = !editable
                                    component.imageView.image = UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray)
                                }
                            ]),
                            tableView: tableView,
                            id: "network-\(index)",
                            hash: value,
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                            },
                            action: editable ? { [weak self] in
                                self?.openSelectNetwork()
                            } : nil
                    )

                    rows.append(row)
                case let .chain(title, value, selected, chainId):
                    let row = CellBuilderNew.row(
                            rootElement: .hStack([
                                .image24 { component in
                                    component.imageView.image = selected ? UIImage(named: "checkbox_active_24") : UIImage(named: "checkbox_diactive_24")
                                },
                                .text { component in
                                    component.font = .subhead2
                                    component.textColor = .themeGray
                                    component.text = title
                                },
                                .text { component in
                                    component.font = .subhead1
                                    component.textColor = .themeLeah
                                    component.text = value
                                }
                            ]),
                            tableView: tableView,
                            id: "chain-\(index)",
                            hash: "\(selected)",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                            },
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

        return [
            Section(id: "wallet_connect", rows: rows)
        ]
    }

}

extension WalletConnectMainViewController {

    enum RowInfo {
        case value(title: String, value: String, valueColor: UIColor?)
        case network(value: String, editable: Bool)
        case chain(title: String, value: String, selected: Bool, chainId: Int)
    }

}
