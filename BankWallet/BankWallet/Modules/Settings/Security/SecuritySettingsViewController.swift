import UIKit
import UIExtensions
import SectionsTableView
import RxSwift

class SecuritySettingsViewController: WalletViewController, SectionsDataSource {
    private let delegate: ISecuritySettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var biometryType: BiometryType = .none
    private var backedUp = false
    private var isPinSet = false
    private var biometricUnlockOn = false

    private var didLoad = false

    init(delegate: ISecuritySettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_security.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerCell(forClass: SettingsRightImageCell.self)
        tableView.registerCell(forClass: SettingsToggleCell.self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()

        tableView.reload()

        didLoad = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var manageAccountsRows = [RowProtocol]()

        let securityAttentionImage = backedUp ? nil : UIImage(named: "Attention Icon")
        manageAccountsRows.append(Row<SettingsRightImageCell>(id: "manage_accounts", height: SettingsTheme.securityCellHeight, autoDeselect: true, bind: { cell, _ in
            cell.bind(titleIcon: UIImage(named: "Key Icon"), title: "settings_security.manage_accounts".localized, rightImage: securityAttentionImage, rightImageTintColor: SettingsTheme.attentionIconTint, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapManageAccounts()
        }))

        sections.append(Section(id: "manage_accounts", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: manageAccountsRows))

        var pinRows = [RowProtocol]()

        pinRows.append(Row<SettingsToggleCell>(id: "pin", height: SettingsTheme.securityCellHeight, bind: { [unowned self] cell, _ in
            cell.bind(titleIcon: UIImage(named: "Passcode Icon"), title: "settings_security.passcode".localized, isOn: self.isPinSet, showDisclosure: false, last: !self.isPinSet, onToggle: { isOn in
                self.delegate.didSwitch(isPinSet: isOn)
            })
        }))

        if isPinSet {
            pinRows.append(Row<SettingsCell>(id: "change_pin", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
                cell.bind(titleIcon: nil, title: "settings_security.change_pin".localized, showDisclosure: true, last: true)
            }, action: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.delegate.didTapEditPin()
                }
            }))
        }

        sections.append(Section(id: "pin", headerState: .margin(height: SettingsTheme.headerHeight), rows: pinRows))

        if isPinSet {
            var biometryRow: RowProtocol?

            switch biometryType {
            case .touchId: biometryRow = createBiometryRow(title: "settings_security.touch_id", icon: "Touch Id Icon", isOn: biometricUnlockOn) 
            case .faceId: biometryRow = createBiometryRow(title: "settings_security.face_id", icon: "Face Id Icon", isOn: biometricUnlockOn)
            default: ()
            }

            if let biometryRow = biometryRow {
                sections.append(Section(id: "biometry", headerState: .margin(height: SettingsTheme.headerHeight), rows: [biometryRow]))
            }
        }

        return sections
    }

    private func reloadIfNeeded() {
        if didLoad {
            tableView.reload()
        }
    }

    private func createBiometryRow(title: String, icon: String, isOn: Bool) -> RowProtocol {
        return Row<SettingsToggleCell>(id: "biometry", height: SettingsTheme.securityCellHeight, bind: { [weak self] cell, _ in
            cell.bind(titleIcon: UIImage(named: icon), title: title.localized, isOn: isOn, showDisclosure: false, last: true, onToggle: { isOn in
                self?.delegate.didSwitch(biometricUnlockOn: isOn)
            })
        })
    }

}

extension SecuritySettingsViewController: ISecuritySettingsView {

    func set(title: String) {
        self.title = title.localized
    }

    func set(biometryType: BiometryType) {
        self.biometryType = biometryType
        reloadIfNeeded()
    }

    func set(backedUp: Bool) {
        self.backedUp = backedUp
        reloadIfNeeded()
    }

    func set(isPinSet: Bool) {
        self.isPinSet = isPinSet
        reloadIfNeeded()
    }

    func set(biometricUnlockOn: Bool) {
        self.biometricUnlockOn = biometricUnlockOn
        reloadIfNeeded()
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
