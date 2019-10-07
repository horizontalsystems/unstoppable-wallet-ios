import UIKit
import SectionsTableView

class RestoreOptionsViewController: WalletViewController {
    private let delegate: IRestoreOptionsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var syncMode: SyncMode = .fast
    private var derivation: MnemonicDerivation = .bip44
    private var didLoad = false

    init(delegate: IRestoreOptionsViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore_options.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))

        tableView.registerCell(forClass: RestoreOptionCell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
        tableView.buildSections()

        didLoad = true
    }

    @objc func onTapDone() {
        delegate.didTapDoneButton()
    }

    private var derivationRows: [RowProtocol] {
        let bip44Selected = derivation == .bip44
        let bip49Selected = derivation == .bip49

        return [
            Row<RestoreOptionCell>(
                    id: "bip44_row",
                    hash: "bip44_\(bip44Selected)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(title: "restore_options.derivation.before_update".localized, subtitle: "restore_options.derivation.bip44".localized, selected: bip44Selected)
                    },
                    action: { [weak self] _ in
                        self?.delegate.onTapBeforeUpdate()
                    }
            ),
            Row<RestoreOptionCell>(
                    id: "bip49_row",
                    hash: "bip49_\(bip49Selected)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(title: "restore_options.derivation.after_update".localized, subtitle: "restore_options.derivation.bip49".localized, selected: bip49Selected, last: true)
                    },
                    action: { [weak self] _ in
                        self?.delegate.onTapAfterUpdate()
                    }
            )
        ]
    }

    private var syncModeRows: [RowProtocol] {
        let fastSelected = syncMode == .fast
        let slowSelected = syncMode == .slow

        return [
            Row<RestoreOptionCell>(
                    id: "fast_row",
                    hash: "fast_\(fastSelected)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(title: "restore_options.sync.fast".localized, subtitle: "restore_options.sync.recommended".localized, selected: fastSelected)
                    },
                    action: { [weak self] _ in
                        self?.delegate.onTapFastSync()
                    }
            ),
            Row<RestoreOptionCell>(
                    id: "slow_row",
                    hash: "slow_\(slowSelected)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(title: "restore_options.sync.slow".localized, subtitle: "restore_options.sync.more_private".localized, selected: slowSelected, last: true)
                    },
                    action: { [weak self] _ in
                        self?.delegate.onTapSlowSync()
                    }
            )
        ]
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

extension RestoreOptionsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        return [
            Section(
                    id: "derivation",
                    headerState: .margin(height: .margin3x),
                    footerState: footer(hash: "derivation_footer", text: "restore_options.derivation.text".localized),
                    rows: derivationRows
            ),
            Section(
                    id: "sync_mode",
                    footerState: footer(hash: "sync_mode_footer", text: "restore_options.sync.text".localized),
                    rows: syncModeRows
            )
        ]
    }

}

extension RestoreOptionsViewController: IRestoreOptionsView {

    func set(syncMode: SyncMode) {
        self.syncMode = syncMode

        if didLoad {
            tableView.reload(animated: true)
        }
    }

    func set(derivation: MnemonicDerivation) {
        self.derivation = derivation

        if didLoad {
            tableView.reload(animated: true)
        }
    }

}
