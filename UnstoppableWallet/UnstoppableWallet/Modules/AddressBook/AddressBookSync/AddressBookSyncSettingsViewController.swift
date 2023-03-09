import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit
import RxSwift

class AddressBookSyncSettingsViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: AddressBookSyncSettingsViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: AddressBookSyncSettingsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.icloud_sync.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()

        subscribe(disposeBag, viewModel.showConfirmationSignal) { [weak self] in self?.showConfirmation() }
    }

    private func showConfirmation() {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.warning".localized,
                items: [
                    .highlightedDescription(text: "settings.icloud_sync.merge_disclaimer".localized)
                ],
                buttons: [
                    .init(style: .yellow, title: "button.continue".localized) { [ weak self] in self?.viewModel.onConfirm() },
                    .init(style: .transparent, title: "button.cancel".localized) { [weak self] in self?.bottomSelectorOnDismiss() }
                ],
                delegate: self
        )

        present(viewController, animated: true)
    }

    private func rootElement(on: Bool, animated: Bool = false) -> CellBuilderNew.CellElement {
        .hStack(
                tableView.universalImage24Elements(
                        title: .body("settings.icloud_sync.contact_book".localized),
                        accessoryType: .switch(
                                isOn: on,
                                animated: animated
                        ) { [weak self] isOn in
                            self?.viewModel.onToggle()
                        }
                )
        )
    }

    private func setToggle(on: Bool) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BaseThemeCell else {
            return
        }

        CellBuilderNew.buildStatic(cell: cell, rootElement: rootElement(on: on, animated: true))
    }

}

extension AddressBookSyncSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "activate_section",
                    headerState: .margin(height: .margin12),
                    footerState: tableView.sectionFooter(text: "settings.icloud_sync.description".localized),
                    rows: [
                        CellBuilderNew.row(
                                rootElement: rootElement(on: viewModel.featureEnabled),
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
    }

}

extension AddressBookSyncSettingsViewController: IBottomSheetDismissDelegate {

    func bottomSelectorOnDismiss() {
        setToggle(on: false)
    }

}