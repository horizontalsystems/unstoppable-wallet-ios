import UIKit
import GrouviExtensions
import SectionsTableViewKit
import RxSwift

class SecuritySettingsViewController: UIViewController, SectionsDataSource {
    let tableView = SectionsTableView(style: .grouped)

    var backedUp = false
    var biometricUnlockOn = false

    var didLoad = false

    var delegate: ISecuritySettingsViewDelegate

    init(delegate: ISecuritySettingsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tableView.registerCell(forClass: SettingsCell.self)
        tableView.registerCell(forClass: SettingsRightImageCell.self)
        tableView.registerCell(forClass: SettingsToggleCell.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = SettingsTheme.separatorColor

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

        view.backgroundColor = AppTheme.controllerBackground

        tableView.reload()

        delegate.viewDidLoad()

        didLoad = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var pinTouchFaceRows = [RowProtocol]()

        if let biometricType = AppHelper.shared.biometricType {
            let createCell: ((String) -> ()) = { title in
                pinTouchFaceRows.append(Row<SettingsToggleCell>(id: "biometrics_id", height: SettingsTheme.securityCellHeight, bind: { [weak self] cell, _ in
                    cell.bind(titleIcon: nil, title: title.localized, isOn: App.shared.localStorage.isBiometricOn, showDisclosure: false, onToggle: { isOn in
                        self?.delegate.didSwitch(biometricUnlockOn: isOn)
                    })
                }))
            }
            switch biometricType {
            case .touchID: createCell("settings_security.touch_id")
            case .faceID: createCell("settings_security.face_id")
            default: ()
            }
        }

        let setOrChangePinTitle = App.shared.pinManager.isPinned ? "settings_security.change_pin".localized : "settings_security.set_pin".localized
        pinTouchFaceRows.append(Row<SettingsCell>(id: "set_pin", hash: "pinned_\(App.shared.pinManager.isPinned)", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: setOrChangePinTitle, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapEditPin()
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: pinTouchFaceRows))

        var backupRows = [RowProtocol]()
        let securityAttentionImage = backedUp ? nil : UIImage(named: "Attention Icon")
        backupRows.append(Row<SettingsRightImageCell>(id: "paper_key", height: SettingsTheme.securityCellHeight, autoDeselect: true, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: "settings_security.paper_key".localized, rightImage: securityAttentionImage, rightImageTintColor: SettingsTheme.attentionIconTint, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapSecretKey()
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.headerHeight), rows: backupRows))

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

    func set(backedUp: Bool) {
        self.backedUp = backedUp
        reloadIfNeeded()
    }

}
