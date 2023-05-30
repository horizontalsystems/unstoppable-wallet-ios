import UIKit
import RxSwift
import ThemeKit
import ComponentKit
import SectionsTableView
import PinKit

class SecuritySettingsViewController: ThemeViewController {
    private let viewModel: SecuritySettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var pinViewItem = SecuritySettingsViewModel.PinViewItem(enabled: false, editVisible: false, biometryViewItem: nil)
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
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.openSetPinSignal) { [weak self] in self?.openSetPin() }
        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }

        loaded = true
    }

    private func sync(pinViewItem: SecuritySettingsViewModel.PinViewItem) {
        self.pinViewItem = pinViewItem
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
        present(App.shared.pinKit.unlockPinModule(
                biometryUnlockMode: .disabled,
                insets: .zero,
                cancellable: true,
                autoDismiss: true,
                onUnlock: { [weak self] in
                    self?.handleUnlock()
                },
                onCancelUnlock: { [weak self] in
                    self?.tableView.reloadData()
                }
        ), animated: true)
    }

    private func handleUnlock() {
        let success = viewModel.onUnlock()

        if !success {
            tableView.reloadData()
        }
    }

}

extension SecuritySettingsViewController: SectionsDataSource {

    private func passcodeRows(viewItem: SecuritySettingsViewModel.PinViewItem) -> [RowProtocol] {
        var elements = tableView.universalImage24Elements(
                image: .local(UIImage(named: "dialpad_alt_2_24")?.withTintColor(.themeGray)),
                title: .body("settings_security.passcode".localized),
                accessoryType: .switch(isOn: viewItem.enabled) { [weak self] in self?.viewModel.onTogglePin(isOn: $0) }
        )
        elements.insert(.image20 { (component: ImageComponent) -> () in
            component.isHidden = viewItem.enabled
            component.imageView.image = UIImage(named: "warning_2_20")?.withTintColor(.themeLucian)
        }, at: 2)

        let passcodeRow = CellBuilderNew.row(
                rootElement: .hStack(elements),
                tableView: tableView,
                id: "passcode",
                hash: "\(viewItem.enabled)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: !viewItem.editVisible)
                }
        )

        var rows: [RowProtocol] = [passcodeRow]

        if viewItem.editVisible {
            let editRow = tableView.universalRow48(
                    id: "edit-passcode",
                    title: .body("settings_security.change_pin".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isLast: true,
                    action: { [weak self] in
                        self?.openEditPin()
                    }
            )

            rows.append(editRow)
        }

        return rows
    }

    private func biometryRow(viewItem: SecuritySettingsViewModel.BiometryViewItem) -> RowProtocol {
        tableView.universalRow48(
                id: "biometry",
                image: .local(UIImage(named: viewItem.icon)?.withTintColor(.themeGray)),
                title: .body(viewItem.title),
                accessoryType: .switch(
                        isOn: viewItem.enabled,
                        onSwitch: { [weak self] isOn in
                            self?.viewModel.onToggleBiometry(isOn: isOn)
                        }),
                hash: "\(viewItem.enabled)",
                isFirst: true,
                isLast: true
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

        return sections
    }

}

extension SecuritySettingsViewController: ISetPinDelegate {

    func didCancelSetPin() {
        tableView.reloadData()
    }

}
