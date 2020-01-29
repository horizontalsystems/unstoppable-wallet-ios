import UIKit
import UIExtensions
import SectionsTableView
import RxSwift
import ThemeKit

class SecuritySettingsViewController: ThemeViewController {
    private let delegate: ISecuritySettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var backupAlertVisible = false
    private var pinSet = false
    private var editPinVisible = false
    private var biometryVisible = false
    private var biometryType: BiometryType = .none
    private var biometryEnabled = false

    init(delegate: ISecuritySettingsViewDelegate) {
        self.delegate = delegate

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

        tableView.registerCell(forClass: TitleCell.self)
        tableView.registerCell(forClass: RightImageCell.self)
        tableView.registerCell(forClass: ToggleCell.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()

        tableView.reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private var manageAccountsRows: [RowProtocol] {
        let securityAttentionImage = backupAlertVisible ? UIImage(named: "Attention Icon") : nil

        return [
            Row<RightImageCell>(id: "manage_accounts", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Wallet Icon"), title: "settings_security.manage_accounts".localized, rightImage: securityAttentionImage, rightImageTintColor: .themeLucian, showDisclosure: true, last: false)
            }, action: { [weak self] _ in
                self?.delegate.didTapManageAccounts()
            }),

            Row<TitleCell>(id: "blockchain_settings", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: UIImage(named: "Block Icon"), title: "settings_security.blockchain_settings".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                self?.delegate.didTapBlockchainSettings()
            })
        ]
    }

    private var pinRows: [RowProtocol] {
        var rows: [RowProtocol] = [
            Row<ToggleCell>(id: "pin", height: .heightSingleLineCell, bind: { [unowned self] cell, _ in
                cell.bind(titleIcon: UIImage(named: "Passcode Icon"), title: "settings_security.passcode".localized, isOn: self.pinSet, last: !self.editPinVisible, onToggle: { [weak self] isOn in
                    self?.delegate.didSwitch(pinSet: isOn)
                })
            })
        ]

        if editPinVisible {
            rows.append(Row<TitleCell>(id: "edit_pin", height: .heightSingleLineCell, bind: { cell, _ in
                cell.bind(titleIcon: nil, title: "settings_security.change_pin".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.delegate.didTapEditPin()
                }
            }))
        }

        return rows
    }

    private var biometryRow: RowProtocol? {
        switch biometryType {
        case .touchId: return createBiometryRow(title: "settings_security.touch_id".localized, icon: "Touch Id Icon")
        case .faceId: return createBiometryRow(title: "settings_security.face_id".localized, icon: "Face Id Icon")
        default: return nil
        }
    }

    private func createBiometryRow(title: String, icon: String) -> RowProtocol {
        return Row<ToggleCell>(id: "biometry", height: .heightSingleLineCell, bind: { [unowned self] cell, _ in
            cell.bind(titleIcon: UIImage(named: icon), title: title, isOn: self.biometryEnabled, last: true, onToggle: { [weak self] isOn in
                self?.delegate.didSwitch(biometryEnabled: isOn)
            })
        })
    }

}

extension SecuritySettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "manage_accounts", headerState: .margin(height: .margin3x), rows: manageAccountsRows),
            Section(id: "pin", headerState: .margin(height: .margin8x), rows: pinRows)
        ]

        if biometryVisible, let biometryRow = biometryRow {
            sections.append(Section(id: "biometry", headerState: .margin(height: .margin8x), rows: [biometryRow]))
        }

        return sections
    }

}

extension SecuritySettingsViewController: ISecuritySettingsView {

    func refresh() {
        tableView.reload()
    }

    func set(backupAlertVisible: Bool) {
        self.backupAlertVisible = backupAlertVisible
    }

    func toggle(pinSet: Bool) {
        self.pinSet = pinSet
    }

    func set(editPinVisible: Bool) {
        self.editPinVisible = editPinVisible
    }

    func set(biometryVisible: Bool) {
        self.biometryVisible = biometryVisible
    }

    func set(biometryType: BiometryType) {
        self.biometryType = biometryType
    }

    func toggle(biometryEnabled: Bool) {
        self.biometryEnabled = biometryEnabled
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
