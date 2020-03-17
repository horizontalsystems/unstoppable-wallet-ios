import UIKit
import SectionsTableView
import ThemeKit

class BlockchainSettingsViewController: ThemeViewController {
    private let delegate: IBlockchainSettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var restoreUrls = [
        "btc.horizontalsystems.xyz/apg",
        "dash.horizontalsystems.xyz/apg",
        "bch.horizontalsystems.xyz/apg"
    ]

    private var settings: BlockchainSetting?
    private var selectedDerivation: MnemonicDerivation?
    private var selectedSyncMode: SyncMode?

    init(delegate: IBlockchainSettingsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerCell(forClass: BlockchainSettingCell.self)
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

    private func handleSelect(derivation: MnemonicDerivation) {
        delegate.onSelect(derivation: derivation)
    }

    private func handleSelect(syncMode: SyncMode) {
        delegate.onSelect(syncMode: syncMode)
    }

    private func derivationRows(selectedDerivation: MnemonicDerivation) -> [RowProtocol] {
        let derivations = MnemonicDerivation.allCases

        return derivations.enumerated().map { (index, derivation) in
            Row<BlockchainSettingCell>(
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
            Row<BlockchainSettingCell>(
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

extension BlockchainSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let derivation = settings?.derivation {
            sections.append(Section(
                    id: "derivation",
                    headerState: header(hash: "derivation_header", text: "coin_settings.derivation.title".localized, additionalMargin: .margin2x),
                    footerState: .margin(height: .margin8x),
                    rows: derivationRows(selectedDerivation: derivation)
            ))
        }

        if let syncMode = settings?.syncMode {
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

extension BlockchainSettingsViewController: IBlockchainSettingsView {

    func set(blockchainName: String) {
        self.title = "blockchain_settings.chain_title".localized(blockchainName.capitalized)
    }

    func set(settings: BlockchainSetting) {
        self.settings = settings
        tableView.reload(animated: true)
    }

    func showChangeAlert(derivation: MnemonicDerivation) {
        let derivationText = derivation.rawValue.uppercased()
        present(BottomAlertViewController(items: [
            .title(title: "blockchain_settings.change_alert.title".localized, subtitle: derivationText, icon: UIImage(named: "Attention Icon"), iconTint: .themeJacob),
            .description(text: "blockchain_settings.change_alert.content".localized),
            .button(title: "blockchain_settings.change_alert.action_button_text".localized(derivationText), button: .appYellow, onTap: { [weak self] in
                self?.delegate.proceedChange(derivation: derivation)
            })
        ]), animated: true)
    }

    func showChangeAlert(syncMode: SyncMode) {
        let syncModeText = syncMode == .slow ? "blockchain_settings.sync_mode.blockchain".localized : "blockchain_settings.sync_mode.api".localized
        present(BottomAlertViewController(items: [
            .title(title: "blockchain_settings.change_alert.title".localized, subtitle: syncModeText, icon: UIImage(named: "Attention Icon"), iconTint: .themeJacob),
            .description(text: "blockchain_settings.sync_mode_change_alert.content".localized),
            .button(title: "blockchain_settings.change_alert.action_button_text".localized(syncModeText), button: .appYellow, onTap: { [weak self] in
                self?.delegate.proceedChange(syncMode: syncMode)
            })
        ]), animated: true)
    }

}
