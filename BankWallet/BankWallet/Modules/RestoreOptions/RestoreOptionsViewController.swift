import UIKit
import SectionsTableView

class RestoreOptionsViewController: WalletViewController, SectionsDataSource {
    private let delegate: IRestoreOptionsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var isFast = true
    private var derivation: MnemonicDerivation = .bip44

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

        tableView.registerCell(forClass: RestoreOptionCell.self)
        tableView.registerHeaderFooter(forClass: SectionHeaderFooterTextView.self)
        tableView.sectionDataSource = self
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        tableView.reload()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))
    }

    private func onTapFastSync() {
        isFast = true
        tableView.reload()
    }

    private func onTapSlowSync() {
        isFast = false
        tableView.reload()
    }

    private func onTapBeforeUpdate() {
        derivation = .bip44
        tableView.reload()
    }

    private func onTapAfterUpdate() {
        derivation = .bip49
        tableView.reload()
    }

    @objc func onTapDone() {
        delegate.didSelectRestoreOptions(isFast: isFast)
    }

    func buildSections() -> [SectionProtocol] {
        let width = view.bounds.size.width

        let derivationText = "restore_options.derivation.text".localized
        let syncModeText = "restore_options.sync.text".localized

        var sections = [SectionProtocol]()

        // Derivations
        let bip44 = Row<RestoreOptionCell>(id: "bip44_row", hash: "bip44", height: .heightDoubleLineCell, bind: { [weak self] cell, _ in
            cell.bind(title: "restore_options.derivation.before_update".localized, subtitle: "restore_options.derivation.bip44".localized, selected: self?.isFast ?? true, last: true)
        }, action: { [weak self] _ in
            self?.onTapFastSync()
        })
        let bip49 = Row<RestoreOptionCell>(id: "bip49_row", hash: "bip49", height: .heightDoubleLineCell, bind: { [weak self] cell, _ in
            cell.bind(title: "restore_options.derivation.after_update".localized, subtitle: "restore_options.derivation.bip49".localized, selected: !(self?.isFast ?? true), last: true)
        }, action: { [weak self] _ in
            self?.onTapSlowSync()
        })
        let derivationFooter: ViewState<SectionHeaderFooterTextView> = .cellType(hash: "derivation_footer", binder: { view in
            view.bind(title: derivationText, topMargin: .margin4x, bottomMargin: .margin8x)
        }, dynamicHeight: { _ in
            return SectionHeaderFooterTextView.textHeight(forContainerWidth: width, text: derivationText, font: .cryptoSubhead2) + .margin12x
        })
        sections.append(Section(id: "derivation", headerState: .margin(height: .margin3x), footerState: derivationFooter, rows: [bip44, bip49]))

        // Sync Modes
        let fastRow = Row<RestoreOptionCell>(id: "fast_row", hash: "fast", height: .heightDoubleLineCell, bind: { [weak self] cell, _ in
            cell.bind(title: "restore_options.sync.fast".localized, subtitle: "restore_options.sync.recommended".localized, selected: self?.derivation == .bip44, last: true)
        }, action: { [weak self] _ in
            self?.onTapBeforeUpdate()
        })
        let slowRow = Row<RestoreOptionCell>(id: "slow_row", hash: "slow", height: .heightDoubleLineCell, bind: { [weak self] cell, _ in
            cell.bind(title: "restore_options.sync.slow".localized, subtitle: "restore_options.sync.more_private".localized, selected: self?.derivation == .bip49, last: true)
        }, action: { [weak self] _ in
            self?.onTapAfterUpdate()
        })
        let syncModeFooter: ViewState<SectionHeaderFooterTextView> = .cellType(hash: "sync_mode_footer", binder: { view in
            view.bind(title: syncModeText, topMargin: .margin4x, bottomMargin: .margin8x)
        }, dynamicHeight: { _ in
            return SectionHeaderFooterTextView.textHeight(forContainerWidth: width, text: syncModeText, font: .cryptoSubhead2) + .margin12x
        })
        sections.append(Section(id: "sync_mode", footerState: syncModeFooter, rows: [fastRow, slowRow]))

        return sections
    }

}

extension RestoreOptionsViewController: IRestoreOptionsView {
}
