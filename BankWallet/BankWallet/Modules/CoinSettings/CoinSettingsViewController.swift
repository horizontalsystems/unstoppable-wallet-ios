import UIKit
import SectionsTableView
import ThemeKit

class CoinSettingsViewController: ThemeViewController {
    private let delegate: ICoinSettingsViewDelegate
    private let mode: CoinSettingsModule.Mode

    private let tableView = SectionsTableView(style: .grouped)

    private var coinTitle: String = ""
    private var restoreUrl: String = ""

    private var derivation: MnemonicDerivation?
    private var syncMode: SyncMode?

    init(delegate: ICoinSettingsViewDelegate, mode: CoinSettingsModule.Mode) {
        self.delegate = delegate
        self.mode = mode

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "coin_settings.enable_button".localized, style: .done, target: self, action: #selector(onTapEnableButton))

        tableView.registerCell(forClass: CoinSettingCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: CoinSettingsHeaderFooterView.self)
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

    @objc func onTapEnableButton() {
        delegate.onTapEnableButton()
    }

    @objc func onTapCancelButton() {
        delegate.onTapCancelButton()
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
        let coinTitle = self.coinTitle

        return syncModes.enumerated().map { (index, syncMode) in
            Row<CoinSettingCell>(
                    id: syncMode.rawValue,
                    hash: "\(syncMode == selectedSyncMode)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(
                                title: syncMode.title(coinTitle: coinTitle),
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

    private func urlFooter(hash: String, text: String, url: String) -> ViewState<CoinSettingsHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text, url: url) { [weak self] in
                        self?.delegate.onTapLink()
                    }
                },
                dynamicHeight: { [unowned self] _ in
                    CoinSettingsHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: text, url: url)
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
                    headerState: header(hash: "derivation_header", text: "coin_settings.derivation.title".localized, additionalMargin: .margin3x),
                    footerState: footer(hash: "derivation_footer", text: "coin_settings.derivation.description_\(mode)".localized),
                    rows: derivationRows(selectedDerivation: derivation)
            ))
        }

        if let syncMode = syncMode {
            sections.append(Section(
                    id: "sync_mode",
                    headerState: header(hash: "sync_mode_header", text: "coin_settings.sync_mode.title".localized),
                    footerState: urlFooter(hash: "sync_mode_footer", text: "coin_settings.sync_mode.description".localized(coinTitle), url: restoreUrl),
                    rows: syncModeRows(selectedSyncMode: syncMode)
            ))
        }

        return sections
    }

}

extension CoinSettingsViewController: ICoinSettingsView {

    func set(coinTitle: String) {
        self.coinTitle = coinTitle
        title = coinTitle
    }

    func set(restoreUrl: String) {
        self.restoreUrl = restoreUrl
    }

    func set(syncMode: SyncMode) {
        self.syncMode = syncMode
    }

    func set(derivation: MnemonicDerivation) {
        self.derivation = derivation
    }

}
