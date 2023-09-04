import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit

class PublicKeysViewController: ThemeViewController {
    private let viewModel: PublicKeysViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: PublicKeysViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "public_keys.title".localized
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

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func openEvmAddress() {
        guard let viewController = EvmAddressModule.viewController(accountType: viewModel.accountType) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openAccountExtendedPublicKey() {
        let viewController = ExtendedKeyModule.viewController(mode: .accountExtendedPublicKey, accountType: viewModel.accountType)
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension PublicKeysViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            )
        ]

        if viewModel.showEvmAddress {
            sections.append(
                    Section(
                            id: "evm-address",
                            footerState: tableView.sectionFooter(text: "public_keys.evm_address.description".localized),
                            rows: [
                                tableView.universalRow48(
                                        id: "evm-address",
                                        title: .body("public_keys.evm_address".localized),
                                        accessoryType: .disclosure,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.openEvmAddress()
                                }
                            ]
                    )
            )
        }

        if viewModel.showAccountExtendedPublicKey {
            sections.append(
                    Section(
                            id: "account-extended-public-key",
                            footerState: tableView.sectionFooter(text: "public_keys.account_extended_public_key.description".localized),
                            rows: [
                                tableView.universalRow48(
                                        id: "account-extended-public-key",
                                        title: .body("public_keys.account_extended_public_key".localized),
                                        accessoryType: .disclosure,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.openAccountExtendedPublicKey()
                                }
                            ]
                    )
            )
        }

        return sections
    }

}
