import Combine
import MarketKit
import SectionsTableView
import SnapKit
import UIKit

class AccountTypeSelectViewController: ThemeViewController {
    private let viewModel: AccountTypeSelectViewModel
    private let accountName: String
    private let statPage: StatPage
    private let showCloseButton: Bool
    private let onRestore: () -> Void
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: AccountTypeSelectViewModel, accountName: String, statPage: StatPage, showCloseButton: Bool = true, onRestore: @escaping () -> Void) {
        self.viewModel = viewModel
        self.accountName = accountName
        self.statPage = statPage
        self.showCloseButton = showCloseButton
        self.onRestore = onRestore

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.select_key_type".localized
        if showCloseButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        }
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        viewModel.openSelectCoinsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accountType in
                self?.openSelectCoins(accountType: accountType)
            }
            .store(in: &cancellables)

        viewModel.onSuccessPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onSuccess()
            }
            .store(in: &cancellables)

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func onSuccess() {
        HudHelper.instance.show(banner: .imported)
        onRestore()
    }

    private func openSelectCoins(accountType: AccountType) {
        let viewController = RestoreSelectModule.viewController(accountName: accountName, accountType: accountType, statPage: statPage, onRestore: onRestore)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AccountTypeSelectViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        let items = viewModel.items

        let rows: [RowProtocol] = items.enumerated().map { index, item in
            tableView.universalRow62(
                id: "item-\(index)",
                title: .body(item.title),
                description: .subhead1(item.description, color: .themeGray),
                accessoryType: .disclosure,
                autoDeselect: true,
                isFirst: index == 0,
                isLast: index == items.count - 1
            ) { [weak self] in
                self?.viewModel.onTap(index: index)
            }
        }

        return [
            Section(
                id: "items",
                headerState: .margin(height: .margin12),
                rows: rows
            ),
        ]
    }
}
