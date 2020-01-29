import UIKit
import SectionsTableView
import ThemeKit

class CoinSettingsViewController: ThemeViewController {
    private let delegate: ICoinSettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var restoreUrls = [
        "btc.horizontalsystems.xyz/apg",
        "dash.horizontalsystems.xyz/apg",
        "bch.horizontalsystems.xyz/apg"
    ]

    private var derivation: MnemonicDerivation?
    private var syncMode: SyncMode?

    init(delegate: ICoinSettingsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_settings.title".localized

        tableView.registerCell(forClass: CoinSettingCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onLoad()
        tableView.buildSections()
    }

    @objc func onTapRightBarButton() {
        delegate.onConfirm()
    }

    private func handleSelect(derivation: MnemonicDerivation) {
        self.derivation = derivation
        delegate.onSelect(derivation: derivation)
        tableView.reload(animated: true)
    }

    private func handleSelect(syncMode: SyncMode) {
        self.syncMode = syncMode
        delegate.onSelect(syncMode: syncMode)
        tableView.reload(animated: true)
    }

    private func derivationRows(selectedDerivation: MnemonicDerivation) -> [RowProtocol] {
        let derivations = MnemonicDerivation.allCases

        return derivations.enumerated().map { (index, derivation) in
            Row<CoinSettingCell>(
                    id: derivation.rawValue,
                    hash: "\(derivation == selectedDerivation)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(
                                title: derivation.title,
                                subtitle: derivation.description,
                                selected: derivation == selectedDerivation,
                                last: index == derivations.count - 1
                        )
                    },
                    action: { [weak self] _ in
                        self?.handleSelect(derivation: derivation)
                    }
            )
        }
    }

    private func syncModeRows(selectedSyncMode: SyncMode) -> [RowProtocol] {
        let syncModes =  [SyncMode.fast, SyncMode.slow]

        return syncModes.enumerated().map { (index, syncMode) in
            Row<CoinSettingCell>(
                    id: syncMode.rawValue,
                    hash: "\(syncMode == selectedSyncMode)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(
                                title: syncMode.title,
                                subtitle: "coin_settings.sync_mode.\(syncMode.rawValue).description".localized,
                                selected: syncMode == selectedSyncMode,
                                last: index == syncModes.count - 1
                        )
                    },
                    action: { [weak self] _ in
                        self?.handleSelect(syncMode: syncMode)
                    }
            )
        }
    }

    private func header(hash: String, text: String, additionalMargin: CGFloat = 0) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height + additionalMargin
                }
        )
    }

    private func footer(hash: String, text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { [unowned self] _ in
                    BottomDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: text)
                }
        )
    }

}

extension CoinSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let derivation = derivation {
            sections.append(Section(
                    id: "derivation",
                    headerState: header(hash: "derivation_header", text: "coin_settings.derivation.title".localized, additionalMargin: .margin2x),
                    footerState: .margin(height: .margin8x),
                    rows: derivationRows(selectedDerivation: derivation)
            ))
        }

        if let syncMode = syncMode {
            sections.append(Section(
                    id: "sync_mode",
                    headerState: header(hash: "sync_mode_header", text: "coin_settings.sync_mode.title".localized),
                    footerState: footer(hash: "sync_mode_footer", text: "coin_settings.sync_mode.description".localized),
                    rows: syncModeRows(selectedSyncMode: syncMode)
            ))
        }

        return sections
    }

}

extension CoinSettingsViewController: ICoinSettingsView {

    func showNextButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(onTapRightBarButton))
    }

    func showRestoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))
    }

    func set(syncMode: SyncMode) {
        self.syncMode = syncMode
    }

    func set(derivation: MnemonicDerivation) {
        self.derivation = derivation
    }

}
