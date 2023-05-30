import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit
import PinKit

class PrivateKeysViewController: ThemeViewController {
    private let viewModel: PrivateKeysViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: PrivateKeysViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "private_keys.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.openEvmPrivateKeySignal) { [weak self] in self?.openEvmPrivateKey(accountType: $0) }
        subscribe(disposeBag, viewModel.openBip32RootKeySignal) { [weak self] in self?.openBip32RootKey(accountType: $0) }
        subscribe(disposeBag, viewModel.openAccountExtendedPrivateKeySignal) { [weak self] in self?.openAccountExtendedPrivateKey(accountType: $0) }

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func openUnlock() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin48, right: 0)
        let viewController = App.shared.pinKit.unlockPinModule(
                biometryUnlockMode: .auto,
                insets: insets,
                cancellable: true,
                autoDismiss: true,
                onUnlock: { [weak self] in
                    self?.viewModel.onUnlock()
                }
        )
        present(viewController, animated: true)
    }

    private func openEvmPrivateKey(accountType: AccountType) {
        guard let viewController = EvmPrivateKeyModule.viewController(accountType: accountType) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openBip32RootKey(accountType: AccountType) {
        let viewController = ExtendedKeyModule.viewController(mode: .bip32RootKey, accountType: accountType)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openAccountExtendedPrivateKey(accountType: AccountType) {
        let viewController = ExtendedKeyModule.viewController(mode: .accountExtendedPrivateKey, accountType: accountType)
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension PrivateKeysViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            )
        ]

        if viewModel.showEvmPrivateKey {
            sections.append(
                    Section(
                            id: "evm-private-key",
                            footerState: tableView.sectionFooter(text: "private_keys.evm_private_key.description".localized),
                            rows: [
                                tableView.universalRow48(
                                        id: "evm-private-key",
                                        title: .body("private_keys.evm_private_key".localized),
                                        accessoryType: .disclosure,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.viewModel.onTapEvmPrivateKey()
                                }
                            ]
                    )
            )
        }

        if viewModel.showBip32RootKey {
            sections.append(
                    Section(
                            id: "bip32-root-key",
                            footerState: tableView.sectionFooter(text: "private_keys.bip32_root_key.description".localized),
                            rows: [
                                tableView.universalRow48(
                                        id: "bip32-root-key",
                                        title: .body("private_keys.bip32_root_key".localized),
                                        accessoryType: .disclosure,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.viewModel.onTapBip32RootKey()
                                }
                            ]
                    )
            )
        }

        if viewModel.showAccountExtendedPrivateKey {
            sections.append(
                    Section(
                            id: "account-extended-private-key",
                            footerState: tableView.sectionFooter(text: "private_keys.account_extended_private_key.description".localized),
                            rows: [
                                tableView.universalRow48(
                                        id: "account-extended-private-key",
                                        title: .body("private_keys.account_extended_private_key".localized),
                                        accessoryType: .disclosure,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.viewModel.onTapAccountExtendedPrivateKey()
                                }
                            ]
                    )
            )
        }

        return sections
    }

}
