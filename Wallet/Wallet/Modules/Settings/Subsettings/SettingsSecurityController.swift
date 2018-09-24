import UIKit
import GrouviExtensions
import SectionsTableViewKit
import RxSwift

class SettingsSecurityController: UIViewController, SectionsDataSource {
    let disposeBag = DisposeBag()
    let tableView = SectionsTableView(style: .grouped)
    var backedUp = false

    init() {
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

        title = "settings_security.title".localized

        view.backgroundColor = AppTheme.controllerBackground

        tableView.reload()

        WordsManager.shared.backedUpSubject.subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] backedUp in
            self?.backedUp = backedUp
            self?.tableView.reload()
            self?.navigationController?.tabBarItem.badgeValue = backedUp ? nil : "1"
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var pinTouchFaceRows = [RowProtocol]()

        if let biometricTitle = BiometricHelper.shared.biometricTitle {
            pinTouchFaceRows.append(Row<SettingsToggleCell>(id: "biometrics_id", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
                cell.bind(titleIcon: nil, title: biometricTitle, isOn: BiometricHelper.shared.isOn, showDisclosure: false, onToggle: { isOn in
                    BiometricHelper.shared.isOn = isOn
                })
            }))
        }

        let setOrChangePinTitle = UnlockHelper.shared.isPinned ? "settings_security.change_pin".localized : "settings_security.set_pin".localized
        pinTouchFaceRows.append(Row<SettingsCell>(id: "set_pin", hash: "pinned_\(UnlockHelper.shared.isPinned)", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: setOrChangePinTitle, showDisclosure: true, last: true)
        }, action: { [weak self] _ in
            if UnlockHelper.shared.isPinned {
                self?.navigationController?.pushViewController(PinRouter.unlockEditPinModule(setDelegate: self), animated: true)
            } else {
                PinRouter.setPinModule(setDelegate: self, from: self)
            }
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: pinTouchFaceRows))

        var backupRows = [RowProtocol]()
        let securityAttentionImage = backedUp ? nil : UIImage(named: "Attention Icon")
        backupRows.append(Row<SettingsRightImageCell>(id: "paper_key", height: SettingsTheme.securityCellHeight, bind: { cell, _ in
            cell.bind(titleIcon: nil, title: "settings_security.paper_key".localized, rightImage: securityAttentionImage, rightImageTintColor: SettingsTheme.attentionIconTint, showDisclosure: true)
        }, action: { [weak self] _ in
            self?.tableView.deselectRow(at: self!.tableView.indexPathForSelectedRow!, animated: true)
            self?.present(BackupRouter.module(dismissMode: .dismissSelf), animated: true)
        }))
        sections.append(Section(id: "security", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), footerState: .margin(height: SettingsTheme.headerHeight), rows: backupRows))

        return sections
    }

}

extension SettingsSecurityController: SetDelegate {
    public func onSet(_ view: PinDismissInterface?) {
        HudHelper.instance.showSuccess()
        navigationController?.popToViewController(self, animated: true)
    }
}
