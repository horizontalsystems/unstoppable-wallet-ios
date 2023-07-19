import UIKit
import UniformTypeIdentifiers
import SectionsTableView
import ThemeKit
import ComponentKit
import RxSwift

class ContactBookSettingsViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: ContactBookSettingsViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private var viewAppeared = false
    private var lostSynchronization = false

    init(viewModel: ContactBookSettingsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "contacts.settings.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()

        subscribe(disposeBag, viewModel.showConfirmationSignal) { [weak self] in self?.showMergeConfirmation() }
        subscribe(disposeBag, viewModel.showSyncErrorDriver) { [weak self] in
            self?.lostSynchronization = $0
            self?.tableView.reload()
        }

        subscribe(disposeBag, viewModel.showRestoreAlertSignal) { [weak self] in self?.showRestoreAlert(contacts: $0) }
        subscribe(disposeBag, viewModel.showParsingErrorSignal) { [weak self] in self?.showParsingError() }
        subscribe(disposeBag, viewModel.showSuccessfulRestoreSignal) { [weak self] in
            HudHelper.instance.show(banner: .success(string: "contacts.restore.restored".localized))
            self?.dismiss(animated: true)
        }
        subscribe(disposeBag, viewModel.showRestoreErrorSignal) { [weak self] in self?.showRestoreError() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !viewAppeared {
            viewAppeared = true
        }
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    private func showRestoreAlert(contacts: [BackupContact]) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.warning".localized,
                items: [
                    .highlightedDescription(text: "contacts.restore.overwrite_alert.description".localized)
                ],
                buttons: [
                    .init(style: .red, title: "contacts.restore.overwrite_alert.replace".localized, actionType: .afterClose) { [weak self] in
                        self?.viewModel.replace(contacts: contacts)
                    },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )
        present(viewController, animated: true)
    }

    private func showParsingError() {
        HudHelper.instance.show(banner: .error(string: "contacts.restore.parsing_error".localized))
    }

    private func showRestoreError() {
        HudHelper.instance.show(banner: .error(string: "contacts.restore.restore_error".localized))
    }

    private func showMergeConfirmation() {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.warning".localized,
                items: [
                    .highlightedDescription(text: "contacts.settings.merge_disclaimer".localized)
                ],
                buttons: [
                    .init(style: .yellow, title: "button.continue".localized) { [ weak self] in self?.viewModel.onConfirm() },
                    .init(style: .transparent, title: "button.cancel".localized) { [weak self] in self?.bottomSelectorOnDismiss() }
                ],
                delegate: self
        )

        present(viewController, animated: true)
    }

    private func goToSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func checkICloudAvailable() {

    }

    private func activationElements(on: Bool, warning: Bool, animated: Bool = false) -> CellBuilderNew.CellElement {
        var elements = tableView.universalImage24Elements(
                title: .body("contacts.settings.icloud_sync".localized),
                accessoryType: .switch(
                        isOn: on,
                        animated: animated
                ) { [weak self] isOn in
                    self?.viewModel.onToggle(isOn: isOn)
                }
        )
        elements.insert(.image20 { (component: ImageComponent) -> () in
            component.isHidden = !(on && warning)
            component.imageView.image = UIImage(named: "warning_2_20")?.withTintColor(.themeLucian)
        }, at: 2)

        return .hStack(elements)
    }

    private func setToggle(on: Bool) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? BaseThemeCell else {
            return
        }

        CellBuilderNew.buildStatic(cell: cell, rootElement: activationElements(on: on, warning: lostSynchronization, animated: true))
    }

    private func onTapRestore() {
        let documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let types = UTType.types(tag: "json", tagClass: UTTagClass.filenameExtension, conformingTo: nil)
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["*.json"], in: .import)
        }

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    private func onTapBackup() {
        do {
            let url = try viewModel.createBackupFile()

            // show share controller with temporary url
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activityViewController, animated: true, completion: nil)
        } catch {
            HudHelper.instance.show(banner: .error(string: "contacts.restore.storage_error".localized))
        }
    }

}

extension ContactBookSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let backupVisible = viewModel.hasContacts

        var manageRows: [RowProtocol] = [
            tableView.universalRow48(
                    id: "restore",
                    image: .local(UIImage(named: "download_24")?.withTintColor(.themeJacob)),
                    title: .body("contacts.settings.restore_contacts".localized, color: .themeJacob),
                    autoDeselect: true,
                    isFirst: true,
                    isLast: !backupVisible,
                    action: { [weak self] in
                        self?.onTapRestore()
                    }
            )
        ]

        if backupVisible {
            manageRows.append(
                    tableView.universalRow48(
                            id: "backup",
                            image: .local(UIImage(named: "icloud_24")?.withTintColor(.themeJacob)),
                            title: .body("contacts.settings.backup_contacts".localized, color: .themeJacob),
                            autoDeselect: true,
                            isLast: true,
                            action: { [weak self] in
                                self?.onTapBackup()
                            }
                    )
            )
        }

        var sections: [SectionProtocol] = [
            Section(
                    id: "manage-contacts",
                    headerState: .margin(height: .margin12),
                    rows: manageRows
            ),
            Section(
                    id: "activate_section",
                    headerState: .margin(height: .margin32),
                    footerState: tableView.sectionFooter(text: "contacts.settings.description".localized),
                    rows: [
                        CellBuilderNew.row(
                                rootElement: activationElements(on: viewModel.featureEnabled, warning: lostSynchronization),
                                tableView: tableView,
                                id: "activate-icloud-contacts",
                                height: .heightCell48,
                                autoDeselect: true,
                                bind: { cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                }
                        )
                    ]
            )
        ]

        if lostSynchronization {
            sections.append(Section(
                    id: "lost_sync_section",
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.highlightedDescriptionRow(id: "lost_connection", style: .red, text: "contacts.settings.lost_synchronization.description".localized)
                    ]
            ))
        }
        return sections
    }

}

extension ContactBookSettingsViewController: IBottomSheetDismissDelegate {

    func bottomSelectorOnDismiss() {
        setToggle(on: false)
    }

}

extension ContactBookSettingsViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let jsonUrl = urls.first {
            viewModel.didPick(url: jsonUrl)
        }
    }

}
