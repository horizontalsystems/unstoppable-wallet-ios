import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView

class BtcBlockchainSettingsViewController: ThemeViewController {
    private let viewModel: BtcBlockchainSettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let iconImageView = UIImageView()

    private let saveButtonHolder = BottomGradientHolder()
    private let saveButton = PrimaryButton()

    private var restoreModeViewItems = [BtcBlockchainSettingsViewModel.ViewItem]()
    private var loaded = false

    init(viewModel: BtcBlockchainSettingsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.cornerRadius = .cornerRadius4
        iconImageView.cornerCurve = .continuous
        iconImageView.setImage(withUrlString: viewModel.iconUrl, placeholder: UIImage(named: "placeholder_rectangle_24"))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        saveButtonHolder.add(to: self, under: tableView)
        saveButtonHolder.addSubview(saveButton)

        saveButton.set(style: .yellow)
        saveButton.setTitle("button.save".localized, for: .normal)
        saveButton.addTarget(self, action: #selector(onTapSave), for: .touchUpInside)

        subscribe(disposeBag, viewModel.restoreModeViewItemsDriver) { [weak self] in self?.sync(restoreModeViewItems: $0) }
        subscribe(disposeBag, viewModel.canSaveDriver) { [weak self] in self?.sync(canSave: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }

        tableView.buildSections()
        loaded = true
    }

    @objc private func onTapSave() {
        viewModel.onTapSave()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private func sync(restoreModeViewItems: [BtcBlockchainSettingsViewModel.ViewItem]) {
        self.restoreModeViewItems = restoreModeViewItems
        reloadTable()
    }

    private func sync(canSave: Bool) {
        saveButton.isEnabled = canSave
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

    private func openRestoreModeInfo() {
        present(InfoModule.restoreSourceInfo, animated: true)
    }

}

extension BtcBlockchainSettingsViewController: SectionsDataSource {

    private func row(id: String, viewItem: BtcBlockchainSettingsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        tableView.universalRow62(
                id: "\(id)-\(index)",
                title: .body(viewItem.name),
                description: .subhead2(viewItem.description),
                accessoryType: .check(viewItem.selected),
                hash: "\(viewItem.selected)",
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "restore-alert",
                    rows: [
                        tableView.highlightedDescriptionRow(id: "restore-alert", text: "btc_blockchain_settings.restore_source.alert".localized(viewModel.title))
                    ]
            ),
            Section(
                    id: "restore-mode",
                    headerState: .margin(height: .margin12),
                    footerState: tableView.sectionFooter(text: "btc_blockchain_settings.restore_source.description".localized),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "btc_blockchain_settings.restore_source".localized) { [weak self] in
                            self?.openRestoreModeInfo()
                        }
                    ] + restoreModeViewItems.enumerated().map { index, viewItem in
                        row(id: "restore", viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == restoreModeViewItems.count - 1) { [weak self] in
                            self?.viewModel.onSelectRestoreMode(index: index)
                        }
                    }
            )
        ]
    }

}
