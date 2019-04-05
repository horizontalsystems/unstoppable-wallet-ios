import UIKit
import GrouviExtensions
import SectionsTableViewKit
import RxSwift

class SecuritySettingsViewController: WalletViewController, SectionsDataSource {
    let tableView = SectionsTableView(style: .grouped)

    var backedUp = false
    var biometricUnlockOn = false
    var biometryType: BiometryType = .none

    var didLoad = false

    var delegate: ISecuritySettingsViewDelegate

    init(delegate: ISecuritySettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerCell(forClass: SettingsRightImageCell.self)
        tableView.registerCell(forClass: SettingsToggleCell.self)
        tableView.registerHeaderFooter(forClass: SectionSeparator.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
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

        var pinTouchFaceRows = [RowProtocol]()

        let createCell: ((String) -> ()) = { title in
            pinTouchFaceRows.append(Row<SettingsToggleCell>(id: "biometrics_id", height: SettingsTheme.securityCellHeight, bind: { [weak self] cell, _ in
                cell.bind(titleIcon: nil, title: title.localized, isOn: App.shared.localStorage.isBiometricOn, showDisclosure: false, onToggle: { isOn in
                    self?.delegate.didSwitch(biometricUnlockOn: isOn)
                })
            }))
        }

        switch biometryType {
        case .touchId: createCell("settings_security.touch_id")
        case .faceId: createCell("settings_security.face_id")
        default: ()
        }

        let setOrChangePinTitle = App.shared.pinManager.isPinSet ? "settings_security.change_pin".localized : "settings_security.set_pin".localized
        pinTouchFaceRows.append(Row<SettingsCell>(id: "set_pin", hash: "pinned_\(App.shared.pinManager.isPinSet)", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: setOrChangePinTitle, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            DispatchQueue.main.async {
                self?.delegate.didTapEditPin()
            }
        }))
        let faceHeader: ViewState<SectionSeparator> = .cellType(hash: "face_header", binder: { view in
            view.bind(showTopSeparator: false)
        }, dynamicHeight: { _ in SettingsTheme.subSettingsHeaderHeight })
        sections.append(Section(id: "face_id", headerState: faceHeader, rows: pinTouchFaceRows))

        var backupRows = [RowProtocol]()
        let securityAttentionImage = backedUp ? nil : UIImage(named: "Attention Icon")
        backupRows.append(Row<SettingsRightImageCell>(id: "backup_wallet", height: SettingsTheme.securityCellHeight, autoDeselect: true, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: "settings_security.backup_wallet".localized, rightImage: securityAttentionImage, rightImageTintColor: SettingsTheme.attentionIconTint, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapBackupWallet()
        }))
        let backupHeader: ViewState<SectionSeparator> = .cellType(hash: "appearance_header", binder: nil, dynamicHeight: { _ in SettingsTheme.headerHeight })
        sections.append(Section(id: "backup", headerState: backupHeader, rows: backupRows))

        var unlinkRows = [RowProtocol]()
        unlinkRows.append(Row<SettingsCell>(id: "unlink", hash: "unlink", height: SettingsTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: "settings_security.unlink_from_this_device".localized, titleColor: SettingsTheme.destructiveTextColor, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapUnlink()
        }))
        let unlinkHeader: ViewState<SectionSeparator> = .cellType(hash: "unlink_header", binder: nil, dynamicHeight: { _ in SettingsTheme.headerHeight })
        let unlinkFooter: ViewState<SectionSeparator> = .cellType(hash: "unlink_header", binder: { view in
            view.bind(showBottomSeparator: false)
        }, dynamicHeight: { _ in 1 })
        sections.append(Section(id: "unlink", headerState: unlinkHeader, footerState: unlinkFooter, rows: unlinkRows))

        return sections
    }

    func reloadIfNeeded() {
        if didLoad {
            tableView.reload()
        }
    }
}

extension SecuritySettingsViewController: ISecuritySettingsView {

    func set(title: String) {
        self.title = title.localized
    }

    func set(biometricUnlockOn: Bool) {
        self.biometricUnlockOn = biometricUnlockOn
        reloadIfNeeded()
    }

    func set(biometryType: BiometryType) {
        self.biometryType = biometryType
        reloadIfNeeded()
    }

    func set(backedUp: Bool) {
        self.backedUp = backedUp
        reloadIfNeeded()
    }

}
