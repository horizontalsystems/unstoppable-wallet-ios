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
    private var transactionModeViewItems = [BtcBlockchainSettingsViewModel.ViewItem]()
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
        iconImageView.setImage(withUrlString: viewModel.iconUrl, placeholder: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        view.addSubview(saveButtonHolder)
        saveButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        saveButtonHolder.addSubview(saveButton)
        saveButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        saveButton.set(style: .yellow)
        saveButton.setTitle("button.save".localized, for: .normal)
        saveButton.addTarget(self, action: #selector(onTapSave), for: .touchUpInside)

        subscribe(disposeBag, viewModel.restoreModeViewItemsDriver) { [weak self] in self?.sync(restoreModeViewItems: $0) }
        subscribe(disposeBag, viewModel.transactionModeViewItemsDriver) { [weak self] in self?.sync(transactionModeViewItems: $0) }
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

    private func sync(transactionModeViewItems: [BtcBlockchainSettingsViewModel.ViewItem]) {
        self.transactionModeViewItems = transactionModeViewItems
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

    private func openTransactionModeInfo() {
        present(InfoModule.transactionInputsOutputsInfo, animated: true)
    }

}

extension BtcBlockchainSettingsViewController: SectionsDataSource {

    private func row(id: String, viewItem: BtcBlockchainSettingsViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.multiText, .image20],
                tableView: tableView,
                id: "\(id)-\(index)",
                hash: "\(viewItem.selected)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0, block: { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.font = .body
                        component.title.textColor = .themeLeah
                        component.subtitle.font = .subhead2
                        component.subtitle.textColor = .themeGray

                        component.title.text = viewItem.name
                        component.subtitle.text = viewItem.description
                    })

                    cell.bind(index: 1, block: { (component: ImageComponent) in
                        component.isHidden = !viewItem.selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    })
                },
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
            ),
            Section(
                    id: "transaction-mode",
                    footerState: tableView.sectionFooter(text: "btc_blockchain_settings.transaction_inputs_outputs.description".localized(viewModel.title)),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "btc_blockchain_settings.transaction_inputs_outputs".localized) { [weak self] in
                            self?.openTransactionModeInfo()
                        }
                    ] + transactionModeViewItems.enumerated().map { index, viewItem in
                        row(id: "transaction", viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == transactionModeViewItems.count - 1) { [weak self] in
                            self?.viewModel.onSelectTransactionMode(index: index)
                        }
                    }
            )
        ]
    }

}
