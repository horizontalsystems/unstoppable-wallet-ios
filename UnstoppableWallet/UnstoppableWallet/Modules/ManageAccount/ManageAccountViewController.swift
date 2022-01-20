import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class ManageAccountViewController: ThemeViewController {
    private let viewModel: ManageAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let nameCell = TextFieldCell()
    private let showRecoveryPhraseCell = BaseSelectableThemeCell()
    private let backupRecoveryPhraseCell = BaseSelectableThemeCell()
    private let unlinkCell = BaseSelectableThemeCell()

    private var keyActionState: ManageAccountViewModel.KeyActionState = .none
    private var isLoaded = false

    init(viewModel: ManageAccountViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.accountName
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .plain, target: self, action: #selector(onTapSaveButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        nameCell.inputText = viewModel.accountName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        showRecoveryPhraseCell.set(backgroundStyle: .lawrence, isFirst: true)
        CellBuilder.build(cell: showRecoveryPhraseCell, elements: [.image20, .text, .image20])
        showRecoveryPhraseCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "key_20")?.withTintColor(.themeGray)
        })
        showRecoveryPhraseCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .b2)
            component.text = "manage_account.show_recovery_phrase".localized
        })
        showRecoveryPhraseCell.bind(index: 2, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
        })

        backupRecoveryPhraseCell.set(backgroundStyle: .lawrence, isFirst: true)
        CellBuilder.build(cell: backupRecoveryPhraseCell, elements: [.image20, .text, .image20, .margin12, .image20])
        backupRecoveryPhraseCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "key_20")?.withTintColor(.themeGray)
        })
        backupRecoveryPhraseCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .b2)
            component.text = "manage_account.backup_recovery_phrase".localized
        })
        backupRecoveryPhraseCell.bind(index: 2, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "warning_2_20")?.withTintColor(.themeLucian)
        })
        backupRecoveryPhraseCell.bind(index: 3, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
        })

        unlinkCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        CellBuilder.build(cell: unlinkCell, elements: [.image20, .text])
        unlinkCell.bind(index: 0, block: { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "trash_20")?.withTintColor(.themeLucian)
        })
        unlinkCell.bind(index: 1, block: { (component: TextComponent) in
            component.set(style: .b5)
            component.text = "manage_account.unlink".localized
        })

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.keyActionStateDriver) { [weak self] in
            self?.keyActionState = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.openShowKeySignal) { [weak self] in self?.openShowKey(account: $0) }
        subscribe(disposeBag, viewModel.openBackupKeySignal) { [weak self] in self?.openBackupKey(account: $0) }
        subscribe(disposeBag, viewModel.openNetworkSettingsSignal) { [weak self] in self?.openNetworkSettings(account: $0) }
        subscribe(disposeBag, viewModel.openUnlinkSignal) { [weak self] in self?.openUnlink(account: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

        tableView.buildSections()

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapSaveButton() {
        viewModel.onSave()
    }

    private func openShowKey(account: Account) {
        guard let viewController = ShowKeyModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
    }

    private func openBackupKey(account: Account) {
        guard let viewController = BackupKeyModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
    }

    private func openNetworkSettings(account: Account) {
        navigationController?.pushViewController(NetworkSettingsModule.viewController(account: account), animated: true)
    }

    private func onTapUnlink() {
        viewModel.onTapUnlink()
    }

    private func openUnlink(account: Account) {
        let viewController = UnlinkModule.viewController(account: account)
        present(viewController, animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload()
    }

}

extension ManageAccountViewController: SectionsDataSource {

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    private var keyActionSection: SectionProtocol {
        var rows = [RowProtocol]()

        switch keyActionState {
        case .showRecoveryPhrase:
            let row = StaticRow(
                    cell: showRecoveryPhraseCell,
                    id: "show-recovery-phrase",
                    height: .heightCell48,
                    autoDeselect: true,
                    action: { [weak self] in
                        self?.viewModel.onTapShowKey()
                    }
            )
            rows.append(row)
        case .backupRecoveryPhrase:
            let row = StaticRow(
                    cell: backupRecoveryPhraseCell,
                    id: "backup-recovery-phrase",
                    height: .heightCell48,
                    autoDeselect: true,
                    action: { [weak self] in
                        self?.viewModel.onTapBackupKey()
                    }
            )
            rows.append(row)
        default: ()
        }

        let isFirst = rows.isEmpty
        let isLast = viewModel.additionalViewItems.isEmpty

        let networkSettingsRow = CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: tableView,
                id: "network-settings",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "blocks_20")?.withTintColor(.themeGray)
                    })
                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = "manage_account.network_settings".localized
                    })
                    cell.bind(index: 2, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)
                    })
                },
                action: { [weak self] in
                    self?.viewModel.onTapNetworkSettings()
                }
        )
        rows.append(networkSettingsRow)

        let viewItems = viewModel.additionalViewItems

        for (index, viewItem) in viewItems.enumerated() {
            let isLast = index == viewItems.count - 1

            let additionalRow = CellBuilder.row(
                    elements: [.image20, .text, .secondaryButton],
                    tableView: tableView,
                    id: "additional-\(index)",
                    height: .heightCell48,
                    bind: { cell in
                        cell.set(backgroundStyle: .lawrence, isLast: isLast)

                        cell.bind(index: 0, block: { (component: ImageComponent) in
                            component.imageView.image = UIImage(named: viewItem.iconName)?.withTintColor(.themeGray)
                        })
                        cell.bind(index: 1, block: { (component: TextComponent) in
                            component.set(style: .b2)
                            component.text = viewItem.title
                        })
                        cell.bind(index: 2, block: { (component: SecondaryButtonComponent) in
                            component.button.set(style: .default)
                            component.button.setTitle(viewItem.value, for: .normal)
                            component.onTap = {
                                CopyHelper.copyAndNotify(value: viewItem.value)
                            }
                        })
                    }
            )

            rows.append(additionalRow)
        }

        return Section(
                id: "key-action",
                footerState: .margin(height: .margin32),
                rows: rows
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "name",
                    headerState: header(text: "manage_account.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            ),
            keyActionSection,
            Section(
                    id: "unlink",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: unlinkCell,
                                id: "unlink",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapUnlink()
                                }
                        )
                    ]
            )
        ]
    }

}
