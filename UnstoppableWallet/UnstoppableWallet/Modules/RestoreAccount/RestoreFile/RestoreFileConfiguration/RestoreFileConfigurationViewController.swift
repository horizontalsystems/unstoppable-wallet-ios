import Combine
import ComponentKit
import Foundation
import SectionsTableView
import ThemeKit
import UIKit

class RestoreFileConfigurationViewController: KeyboardAwareViewController {
    private let viewModel: RestoreFileConfigurationViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = BottomGradientHolder()
    private let restoreButton = PrimaryButton()

    init(viewModel: RestoreFileConfigurationViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup_app.backup_list.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(restoreButton)

        restoreButton.setTitle("button.restore".localized, for: .normal)
        restoreButton.addTarget(self, action: #selector(onTapRestore), for: .touchUpInside)
        restoreButton.set(style: .yellow)

        viewModel.showMergeAlertPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showMergeAlert()
            }
            .store(in: &cancellables)

        viewModel.finishedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] success in
                self?.finish(success: success)
            }
            .store(in: &cancellables)

        tableView.buildSections()
    }

    @objc private func onCancel() {
        (returnViewController ?? self)?.dismiss(animated: true)
    }

    private func finish(success: Bool) {
        UIApplication.shared.windows.first { $0.isKeyWindow }?.set(newRootController: MainModule.instance(presetTab: .balance))

        if success {
            HudHelper.instance.show(banner: .done)
        }
    }

    @objc private func onTapRestore() {
        viewModel.onTapRestore()
    }

    private func showMergeAlert() {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "alert.notice".localized,
                items: [
                    .highlightedDescription(text: "backup_app.restore.notice.description".localized),
                ],
                buttons: [
                    .init(style: .red, title: "backup_app.restore.notice.merge".localized, actionType: .afterClose) { [weak self] in
                        self?.viewModel.restore()
                    },
                    .init(style: .transparent, title: "button.cancel".localized, actionType: .afterClose),
                ]
        )

        present(viewController, animated: true)
    }

    private func row(accountItem: BackupAppModule.AccountItem, rowInfo: RowInfo) -> RowProtocol {
        let subtitleColor: UIColor = accountItem.cautionType?.labelColor ?? .themeGray

        return tableView.universalRow62(
            id: accountItem.id,
            title: .body(accountItem.name),
            description: .subhead2(accountItem.description, color: subtitleColor),
            isFirst: rowInfo.isFirst,
            isLast: rowInfo.isLast
        )
    }

    private func row(item: BackupAppModule.Item, rowInfo: RowInfo) -> RowProtocol {
        if let description = item.description {
            return tableView.universalRow62(
                    id: item.title,
                    title: .body(item.title),
                    description: .subhead2(description),
                    isFirst: rowInfo.isFirst,
                    isLast: rowInfo.isLast
            )
        } else {
            return tableView.universalRow48(
                    id: item.title,
                    title: .body(item.title),
                    value: .subhead1(item.value, color: .themeGray),
                    isFirst: rowInfo.isFirst,
                    isLast: rowInfo.isLast
            )
        }
    }

    private var descriptionSection: SectionProtocol {
        Section(
            id: "description",
            headerState: .margin(height: .margin12),
            footerState: .margin(height: .margin32),
            rows: [
                tableView.descriptionRow(
                    id: "description",
                    text: "backup_app.backup_list.description.restore".localized,
                    font: .subhead2,
                    textColor: .themeGray,
                    ignoreBottomMargin: true
                ),
            ]
        )
    }
}

extension RestoreFileConfigurationViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            descriptionSection,
        ]

        if !viewModel.accountItems.isEmpty {
            sections.append(
                Section(
                    id: "wallets-section",
                    headerState: tableView.sectionHeader(text: "backup_app.backup_list.header.wallets".localized),
                    footerState: .margin(height: .margin24),
                    rows: viewModel.accountItems
                        .enumerated()
                        .map { index, item in row(accountItem: item, rowInfo: RowInfo(index: index, count: viewModel.accountItems.count)) }
                )
            )
        }

        if !viewModel.otherItems.isEmpty {
            sections.append(
                Section(
                    id: "other-section",
                    headerState: tableView.sectionHeader(text: "backup_app.backup_list.header.other".localized),
                    footerState: .margin(height: .margin32),
                    rows: viewModel.otherItems
                        .enumerated()
                        .map { index, item in row(item: item, rowInfo: RowInfo(index: index, count: viewModel.otherItems.count)) }
                )
            )
        }

        return sections
    }
}
