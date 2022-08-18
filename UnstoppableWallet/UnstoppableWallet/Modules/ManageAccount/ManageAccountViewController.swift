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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .done, target: self, action: #selector(onTapSave))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        nameCell.inputText = viewModel.accountName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.keyActionStateDriver) { [weak self] in
            self?.keyActionState = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.openRecoveryPhraseSignal) { [weak self] in self?.openRecoveryPhrase(account: $0) }
        subscribe(disposeBag, viewModel.openEvmPrivateKeySignal) { [weak self] in self?.openEvmPrivateKey(account: $0) }
        subscribe(disposeBag, viewModel.openPublicKeysSignal) { [weak self] in self?.openPublicKeys(account: $0) }
        subscribe(disposeBag, viewModel.openBackupSignal) { [weak self] in self?.openBackup(account: $0) }
        subscribe(disposeBag, viewModel.openUnlinkSignal) { [weak self] in self?.openUnlink(account: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }

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

        present(viewController, animated: true)
    }

    private func openEvmPrivateKey(account: Account) {
        guard let viewController = EvmPrivateKeyModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
    }

    private func openPublicKeys(account: Account) {
        guard let viewController = PublicKeysModule.viewController(account: account) else {
            return
        }

        present(viewController, animated: true)
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

}

extension ManageAccountViewController: SectionsDataSource {

    private func keyActionSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        switch keyActionState {
        case .showRecoveryPhrase:
            sections.append(
                    Section(
                            id: "show-actions",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.imageTitleRow(
                                        id: "recovery-phrase",
                                        image: UIImage(named: "paper_contract_20"),
                                        title: "manage_account.recovery_phrase".localized,
                                        color: .themeJacob,
                                        autoDeselect: true,
                                        isFirst: true
                                ) { [weak self] in
                                    self?.viewModel.onTapRecoveryPhrase()
                                },
                                tableView.imageTitleRow(
                                        id: "evm-private-key",
                                        image: UIImage(named: "key_20"),
                                        title: "manage_account.evm_private_key".localized,
                                        color: .themeJacob,
                                        autoDeselect: true
                                ) { [weak self] in
                                    self?.viewModel.onTapEvmPrivateKey()
                                },
                                tableView.imageTitleRow(
                                        id: "public-keys",
                                        image: UIImage(named: "link_20"),
                                        title: "manage_account.public_keys".localized,
                                        color: .themeJacob,
                                        autoDeselect: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.viewModel.onTapPublicKeys()
                                }
                            ]
                    )
            )

            let additionalViewItems = viewModel.additionalViewItems

            if !additionalViewItems.isEmpty {
                sections.append(
                        Section(
                                id: "additional",
                                footerState: .margin(height: .margin32),
                                rows: additionalViewItems.enumerated().map { index, viewItem in
                                    let isFirst = index == 0
                                    let isLast = index == additionalViewItems.count - 1

                                    return CellBuilderNew.row(
                                            rootElement: .hStack([
                                                .image20 { component in
                                                    component.setImage(urlString: viewItem.imageUrl, placeholder: nil)
                                                },
                                                .text { component in
                                                    component.font = .body
                                                    component.textColor = .themeLeah
                                                    component.text = viewItem.title
                                                },
                                                .secondaryButton { component in
                                                    component.button.set(style: .default)
                                                    component.button.setTitle(viewItem.value, for: .normal)
                                                    component.onTap = {
                                                        CopyHelper.copyAndNotify(value: viewItem.value)
                                                    }
                                                }
                                            ]),
                                            tableView: tableView,
                                            id: "additional-\(index)",
                                            height: .heightCell48,
                                            bind: { cell in
                                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                            }
                                    )
                                }
                        )
                )
            }
        case .backupRecoveryPhrase:
            sections.append(
                    Section(
                            id: "backup-actions",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.imageTitleRow(
                                        id: "backup-recovery-phrase",
                                        image: UIImage(named: "warning_2_20"),
                                        title: "manage_account.backup_recovery_phrase".localized,
                                        color: .themeJacob,
                                        autoDeselect: true,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.viewModel.onTapBackup()
                                }
                            ]
                    )
            )
        default: ()
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

        sections.append(contentsOf: keyActionSections())

        sections.append(
                Section(
                        id: "unlink",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.imageTitleRow(
                                    id: "unlink",
                                    image: UIImage(named: "trash_20"),
                                    title: "manage_account.unlink".localized,
                                    color: .themeLucian,
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
