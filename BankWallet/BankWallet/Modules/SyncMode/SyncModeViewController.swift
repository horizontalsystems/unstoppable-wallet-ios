import UIKit
import SectionsTableView

class SyncModeViewController: WalletViewController, SectionsDataSource {
    private let delegate: ISyncModeViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var isFast = true

    init(delegate: ISyncModeViewDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_sync.title".localized

        tableView.registerCell(forClass: SyncModeCell.self)
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

    @objc func onTapDone() {
        delegate.didSelectSyncMode(isFast: isFast)
    }

    func buildSections() -> [SectionProtocol] {
        let width = view.bounds.size.width

        var sections = [SectionProtocol]()

        let fastRow = Row<SyncModeCell>(id: "fast_row", hash: "fast", height: SyncModeTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.bind(title: "coin_sync.fast".localized, description: "coin_sync.recommended".localized, selected: self?.isFast ?? true, first: true, last: true)
        }, action: { [weak self] _ in
            self?.onTapFastSync()
        })
        let fastFooter: ViewState<SectionHeaderFooterTextView> = .cellType(hash: "sync_fast_footer", binder: { view in
            view.bind(title: "coin_sync.fast.text".localized, topMargin: SyncModeTheme.cellBigMargin, bottomMargin: SyncModeTheme.separatorBottomMargin)
        }, dynamicHeight: { _ in
            return SectionHeaderFooterTextView.height(forContainerWidth: width, text: "coin_sync.fast.text".localized, font: AppTheme.footerTextFont, additionalMargins: SyncModeTheme.cellBigMargin + SyncModeTheme.separatorBottomMargin)
        })
        sections.append(Section(id: "fast", footerState: fastFooter, rows: [fastRow]))

        let slowRow = Row<SyncModeCell>(id: "slow_row", hash: "slow", height: SyncModeTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.bind(title: "coin_sync.slow".localized, description: "coin_sync.more_private".localized, selected: !(self?.isFast ?? true), first: true, last: true)
        }, action: { [weak self] _ in
            self?.onTapSlowSync()
        })
        let slowFooter: ViewState<SectionHeaderFooterTextView> = .cellType(hash: "sync_slow_footer", binder: { view in
            view.bind(title: "coin_sync.slow.text".localized, topMargin: SyncModeTheme.cellBigMargin, bottomMargin: SyncModeTheme.separatorBottomMargin)
        }, dynamicHeight: { _ in
            return SectionHeaderFooterTextView.height(forContainerWidth: width, text: "coin_sync.slow.text".localized, font: AppTheme.footerTextFont, additionalMargins: SyncModeTheme.cellBigMargin + SyncModeTheme.separatorBottomMargin)
        })
        sections.append(Section(id: "fast", footerState: slowFooter, rows: [slowRow]))

        return sections
    }

}

extension SyncModeViewController: ISyncModeView {
}
