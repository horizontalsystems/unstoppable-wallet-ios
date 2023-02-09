import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit
import PinKit

class ManageAccountViewController: ThemeViewController {
    private let viewModel: ManageAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let nameCell = TextFieldCell()

    private var warningViewItem: CancellableTitledCaution?
    private var keyActionGroups = [[ManageAccountViewModel.KeyAction]]()
    private var isLoaded = false

    private weak var sourceViewController: ManageAccountsViewController?

    init(viewModel: ManageAccountViewModel, sourceViewController: ManageAccountsViewController) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.accountName
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .done, target: self, action: #selector(onTapSave))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)

        nameCell.inputText = viewModel.accountName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.keyActionGroupsDriver) { [weak self] in
            self?.keyActionGroups = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.showWarningDriver) { [weak self] in self?.sync(warning: $0) }
        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.openRecoveryPhraseSignal) { [weak self] in self?.openRecoveryPhrase(account: $0) }
        subscribe(disposeBag, viewModel.openEvmPrivateKeySignal) { [weak self] in self?.openEvmPrivateKey(account: $0) }
        subscribe(disposeBag, viewModel.openBip32RootKeySignal) { [weak self] in self?.openBip32RootKey(account: $0) }
        subscribe(disposeBag, viewModel.openAccountExtendedPrivateKeySignal) { [weak self] in self?.openAccountExtendedPrivateKey(account: $0) }
        subscribe(disposeBag, viewModel.openAccountExtendedPublicKeySignal) { [weak self] in self?.openAccountExtendedPublicKey(account: $0) }
        subscribe(disposeBag, viewModel.openBackupSignal) { [weak self] in self?.openBackup(account: $0) }
        subscribe(disposeBag, viewModel.openUnlinkSignal) { [weak self] in self?.openUnlink(account: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true) { [weak self] in
                self?.sourceViewController?.handleDismiss()
            }
        }

        tableView.buildSections()

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapSave() {
        viewModel.onSave()
    }

    private func openUnlock() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin48, right: 0)
        let viewController = App.shared.pinKit.unlockPinModule(delegate: self, biometryUnlockMode: .disabled, insets: insets, cancellable: true, autoDismiss: true)
        present(viewController, animated: true)
    }

    private func openRecoveryPhrase(account: Account) {
        guard let viewController = RecoveryPhraseModule.viewController(account: account) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openEvmPrivateKey(account: Account) {
        guard let viewController = EvmPrivateKeyModule.viewController(account: account) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openBip32RootKey(account: Account) {
        let viewController = ExtendedKeyModule.viewController(mode: .bip32RootKey, accountType: account.type)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openAccountExtendedPrivateKey(account: Account) {
        let viewController = ExtendedKeyModule.viewController(mode: .accountExtendedPrivateKey, accountType: account.type)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openAccountExtendedPublicKey(account: Account) {
        let viewController = ExtendedKeyModule.viewController(mode: .accountExtendedPublicKey, accountType: account.type)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openBackup(account: Account) {
        guard let viewController = BackupModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
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

    private func sync(warning: CancellableTitledCaution?) {
        warningViewItem = warning
        tableView.reloadData()
    }

    private func onOpenWarning() {
        guard let url = viewModel.warningUrl else {
            return
        }
        let module = MarkdownModule.viewController(url: url)
        DispatchQueue.main.async {
            let controller = ThemeNavigationController(rootViewController: module)
            return self.present(controller, animated: true)
        }
    }

}

extension ManageAccountViewController: SectionsDataSource {

    private func row(keyAction: ManageAccountViewModel.KeyAction, isFirst: Bool, isLast: Bool) -> RowProtocol {
        switch keyAction {
        case .showRecoveryPhrase:
            return tableView.universalRow48(
                    id: "show-recovery-phrase",
                    image: .local(UIImage(named: "paper_contract_24")),
                    title: .body("manage_account.recovery_phrase".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapRecoveryPhrase()
            }
        case .showEvmPrivateKey:
            return tableView.universalRow48(
                    id: "show-evm-private-key",
                    image: .local(UIImage(named: "key_24")),
                    title: .body("manage_account.evm_private_key".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapEvmPrivateKey()
            }
        case .showBip32RootKey:
            return tableView.universalRow48(
                    id: "show-bip-32-root-key",
                    image: .local(UIImage(named: "key_24")),
                    title: .body("manage_account.bip32_root_key".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapBip32RootKey()
            }
        case .showAccountExtendedPrivateKey:
            return tableView.universalRow48(
                    id: "show-account-extended-private-key",
                    image: .local(UIImage(named: "key_24")),
                    title: .body("manage_account.account_extended_private_key".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapAccountExtendedPrivateKey()
            }
        case .showAccountExtendedPublicKey:
            return tableView.universalRow48(
                    id: "show-account-extended-public-key",
                    image: .local(UIImage(named: "link_24")),
                    title: .body("manage_account.account_extended_public_key".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapAccountExtendedPublicKey()
            }
        case .backupRecoveryPhrase:
            return tableView.universalRow48(
                    id: "backup-recovery-phrase",
                    image: .local(UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)),
                    title: .custom("manage_account.backup_recovery_phrase".localized, .body, .themeLucian),
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapBackup()
            }
        }
    }

    private func keyActionSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if !keyActionGroups.isEmpty {
            for (index, keyActionGroup) in keyActionGroups.enumerated() {
                sections.append(
                        Section(
                                id: "actions-\(index)",
                                footerState: .margin(height: .margin32),
                                rows: keyActionGroup.enumerated().map { index, keyAction in
                                    row(keyAction: keyAction, isFirst: index == 0, isLast: index == keyActionGroup.count - 1)
                                }
                        )
                )
            }
        }

        return sections
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "name",
                    headerState: tableView.sectionHeader(text: "manage_account.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            )
        ]

        if let warningViewItem = warningViewItem {
            sections.append(
                    Section(
                        id: "migration-warning",
                        footerState: .margin(height: .margin32),
                        rows: [
                            Row<TitledHighlightedDescriptionCell>(
                                    id: "migration-cell",
                                    dynamicHeight: { [weak self] containerWidth in
                                        let text = self?.warningViewItem?.text ?? ""
                                        return TitledHighlightedDescriptionCell.height(containerWidth: containerWidth, text: text)
                                    },
                                    bind: { [weak self] cell, _ in
                                        cell.set(backgroundStyle: .transparent, isFirst: true)
                                        cell.bind(caution: warningViewItem)
                                        cell.onBackgroundButton = { self?.onOpenWarning() }
                                    }
                            )
                        ]
                    )
            )
        }

        sections.append(contentsOf: keyActionSections())

        sections.append(
                Section(
                        id: "unlink",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.universalRow48(
                                    id: "unlink",
                                    image: .local(UIImage(named: "trash_24")?.withTintColor(.themeLucian)),
                                    title: .custom("manage_account.unlink".localized, .body, .themeLucian),
                                    autoDeselect: true,
                                    isFirst: true,
                                    isLast: true
                            ) { [weak self] in
                                self?.onTapUnlink()
                            }
                        ]
                )
        )

        return sections
    }

}

extension ManageAccountViewController: IUnlockDelegate {

    func onUnlock() {
        viewModel.onUnlock()
    }

    func onCancelUnlock() {
    }

}
