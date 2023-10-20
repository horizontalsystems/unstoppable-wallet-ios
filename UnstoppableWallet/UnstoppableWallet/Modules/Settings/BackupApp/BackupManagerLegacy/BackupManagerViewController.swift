import Combine
import SectionsTableView
import SwiftUI
import ThemeKit
import UIKit

class BackupManagerViewController: ThemeViewController {
    private let viewModel: BackupManagerViewModel
    private let tableView = SectionsTableView(style: .grouped)

    private var cancellables = Set<AnyCancellable>()

    init(viewModel: BackupManagerViewModel) {
        self.viewModel = viewModel
        super.init()

        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup_app.backup_manager.title".localized
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        viewModel
            .openUnlockPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in self?.onUnlock() })
            .store(in: &cancellables)

        viewModel
            .openBackupPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in self?.onCreate() })
            .store(in: &cancellables)

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func onRestore() {
        let viewController = RestoreTypeModule.viewController(type: .full, sourceViewController: self)
        present(viewController, animated: true)
    }

    private func onUnlock() {
        let viewController = UnlockModule.moduleUnlockView { [weak self] in
                self?.viewModel.unlock()
            }.toNavigationViewController()

        present(viewController, animated: true)
    }

    private func onCreate() {
        let viewController = BackupAppModule
            .view { [weak self] in
                self?.presentedViewController?.dismiss(animated: true)
            }.toNavigationViewController()

        self.present(viewController, animated: true)
    }
}

extension BackupManagerViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "type-section",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    tableView.universalRow48(
                        id: "restore",
                        image: .local(UIImage(named: "download_24")?.withTintColor(.themeJacob)),
                        title: .body("backup_app.backup_manager.restore".localized, color: .themeJacob),
                        backgroundStyle: .lawrence,
                        autoDeselect: true,
                        isFirst: true,
                        isLast: false
                    ) { [weak self] in
                        self?.onRestore()
                    },
                    tableView.universalRow48(
                        id: "create",
                        image: .local(UIImage(named: "plus_24")?.withTintColor(.themeJacob)),
                        title: .body("backup_app.backup_manager.create".localized, color: .themeJacob),
                        backgroundStyle: .lawrence,
                        autoDeselect: true,
                        isFirst: false,
                        isLast: true
                    ) { [weak self] in
                        self?.viewModel.onTapBackup()
                    },
                ]
            ),
        ]
    }
}
