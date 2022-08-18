import UIKit
import SectionsTableView
import RxSwift
import ThemeKit
import ComponentKit
import PinKit
import MarketKit

class SecuritySettingsViewController: ThemeViewController {
    private let viewModel: SecuritySettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var pinViewItem = SecuritySettingsViewModel.PinViewItem(enabled: false, editVisible: false, biometryViewItem: nil)
    private var blockchainViewItems = [SecuritySettingsViewModel.BlockchainViewItem]()
    private var loaded = false

    init(viewModel: SecuritySettingsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_security.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.pinViewItemDriver) { [weak self] in self?.sync(pinViewItem: $0) }
        subscribe(disposeBag, viewModel.blockchainViewItemsDriver) { [weak self] in self?.sync(blockchainViewItems: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.openSetPinSignal) { [weak self] in self?.openSetPin() }
        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.openBtcBlockchainSignal) { [weak self] in self?.openBtc(blockchain: $0) }
        subscribe(disposeBag, viewModel.openEvmBlockchainSignal) { [weak self] in self?.openEvm(blockchain: $0) }

        loaded = true
    }

    private func sync(pinViewItem: SecuritySettingsViewModel.PinViewItem) {
        self.pinViewItem = pinViewItem
        reloadTable()
    }

    private func sync(blockchainViewItems: [SecuritySettingsViewModel.BlockchainViewItem]) {
        self.blockchainViewItems = blockchainViewItems
        reloadTable()
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        } else {
            tableView.buildSections()
        }
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func openSetPin() {
        present(App.shared.pinKit.setPinModule(delegate: self), animated: true)
    }

    private func openEditPin() {
        present(App.shared.pinKit.editPinModule, animated: true)
    }

    private func openUnlock() {
        present(App.shared.pinKit.unlockPinModule(delegate: self, biometryUnlockMode: .disabled, insets: .zero, cancellable: true, autoDismiss: true), animated: true)
    }

    private func openBtc(blockchain: Blockchain) {
        present(BtcBlockchainSettingsModule.viewController(blockchain: blockchain), animated: true)
    }

    private func openEvm(blockchain: Blockchain) {
        present(EvmNetworkModule.viewController(blockchain: blockchain), animated: true)
    }

}

extension SecuritySettingsViewController: SectionsDataSource {

    private func passcodeRows(viewItem: SecuritySettingsViewModel.PinViewItem) -> [RowProtocol] {
        let passcodeRow = CellBuilder.row(
                elements: [.image20, .text, .image20, .switch],
                tableView: tableView,
                id: "passcode",
                hash: "\(viewItem.enabled)",
                height: .heightCell48,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !viewItem.editVisible)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "dialpad_alt_2_20")?.withTintColor(.themeGray)
                    })

                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = "settings_security.passcode".localized
                    })

                    cell.bind(index: 2, block: { (component: ImageComponent) in
                        component.isHidden = viewItem.enabled
                        component.imageView.image = UIImage(named: "warning_2_20")?.withTintColor(.themeLucian)
                    })

                    cell.bind(index: 3, block: { (component: SwitchComponent) in
                        component.switchView.isOn = viewItem.enabled
                        component.onSwitch = { isOn in
                            self?.viewModel.onTogglePin(isOn: isOn)
                        }
                    })
                }
        )

        var rows: [RowProtocol] = [passcodeRow]

        if viewItem.editVisible {
            let editRow = CellBuilder.selectableRow(
                    elements: [.text, .image20],
                    tableView: tableView,
                    id: "edit-passcode",
                    height: .heightCell48,
                    autoDeselect: true,
                    bind: { cell in
                        cell.set(backgroundStyle: .lawrence, isLast: true)

                        cell.bind(index: 0, block: { (component: TextComponent) in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = "settings_security.change_pin".localized
                        })

                        cell.bind(index: 1, block: { (component: ImageComponent) in
                            component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                        })
                    },
                    action: { [weak self] in
                        self?.openEditPin()
                    }
            )

            rows.append(editRow)
        }

        return rows
    }

    private func biometryRow(viewItem: SecuritySettingsViewModel.BiometryViewItem) -> RowProtocol {
        CellBuilder.row(
                elements: [.image20, .text, .switch],
                tableView: tableView,
                id: "biometry",
                hash: "\(viewItem.enabled)",
                height: .heightCell48,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: viewItem.icon)?.withTintColor(.themeGray)
                    })

                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = viewItem.title
                    })

                    cell.bind(index: 2, block: { (component: SwitchComponent) in
                        component.switchView.isOn = viewItem.enabled
                        component.onSwitch = { isOn in
                            self?.viewModel.onToggleBiometry(isOn: isOn)
                        }
                    })
                }
        )
    }

    private func blockchainRow(viewItem: SecuritySettingsViewModel.BlockchainViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .multiText, .image20],
                tableView: tableView,
                id: "blockchain-\(index)",
                hash: "\(viewItem.value)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.iconUrl, placeholder: nil)
                    })

                    cell.bind(index: 1, block: { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.font = .body
                        component.title.textColor = .themeLeah
                        component.subtitle.font = .subhead2
                        component.subtitle.textColor = .themeGray

                        component.title.text = viewItem.name
                        component.subtitle.text = viewItem.value
                    })

                    cell.bind(index: 2, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    })
                },
                action: { [weak self] in
                    self?.viewModel.onTapBlockchain(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        let passcodeSection = Section(
                id: "passcode",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin24),
                rows: passcodeRows(viewItem: pinViewItem)
        )
        sections.append(passcodeSection)

        if let biometryViewItem = pinViewItem.biometryViewItem {
            let biometrySection = Section(
                    id: "biometry",
                    footerState: .margin(height: .margin32),
                    rows: [
                        biometryRow(viewItem: biometryViewItem)
                    ]
            )
            sections.append(biometrySection)
        }

        let blockchainSection = Section(
                id: "blockchains",
                headerState: tableView.sectionHeader(text: "settings_security.blockchain_settings".localized),
                footerState: .margin(height: .margin32),
                rows: blockchainViewItems.enumerated().map { index, viewItem in
                    blockchainRow(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == blockchainViewItems.count - 1)
                }
        )
        sections.append(blockchainSection)

        return sections
    }

}

extension SecuritySettingsViewController: ISetPinDelegate {

    func didCancelSetPin() {
        tableView.reloadData()
    }

}

extension SecuritySettingsViewController: IUnlockDelegate {

    func onUnlock() {
        let success = viewModel.onUnlock()

        if !success {
            tableView.reloadData()
        }
    }

    func onCancelUnlock() {
        tableView.reloadData()
    }

}
