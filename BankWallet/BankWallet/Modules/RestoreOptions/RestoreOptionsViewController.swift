import UIKit
import SectionsTableView

class RestoreOptionsViewController: WalletViewController, SectionsDataSource {
    private let delegate: IRestoreOptionsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var isFast = true

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

    @objc func onTapDone() {
        delegate.didSelectRestoreOptions(isFast: isFast)
    }

    func buildSections() -> [SectionProtocol] {
        let width = view.bounds.size.width
        let footerMargins = RestoreOptionsTheme.cellBigMargin + RestoreOptionsTheme.separatorBottomMargin

        let fastText = "restore_options.sync.fast.text".localized
        let slowText = "restore_options.sync.slow.text".localized

        var sections = [SectionProtocol]()

        let fastRow = Row<RestoreOptionCell>(id: "fast_row", hash: "fast", height: RestoreOptionsTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.bind(title: "restore_options.sync.fast".localized, description: "restore_options.sync.recommended".localized, selected: self?.isFast ?? true, first: true, last: true)
        }, action: { [weak self] _ in
            self?.onTapFastSync()
        })
        let fastFooter: ViewState<SectionHeaderFooterTextView> = .cellType(hash: "sync_fast_footer", binder: { view in
            view.bind(title: fastText, topMargin: RestoreOptionsTheme.cellBigMargin, bottomMargin: RestoreOptionsTheme.separatorBottomMargin)
        }, dynamicHeight: { _ in
            return SectionHeaderFooterTextView.textHeight(forContainerWidth: width, text: fastText, font: AppTheme.footerTextFont) + footerMargins
        })
        sections.append(Section(id: "fast", headerState: .margin(height: RestoreOptionsTheme.topMargin), footerState: fastFooter, rows: [fastRow]))

        let slowRow = Row<RestoreOptionCell>(id: "slow_row", hash: "slow", height: RestoreOptionsTheme.cellHeight, bind: { [weak self] cell, _ in
            cell.bind(title: "restore_options.sync.slow".localized, description: "restore_options.sync.more_private".localized, selected: !(self?.isFast ?? true), first: true, last: true)
        }, action: { [weak self] _ in
            self?.onTapSlowSync()
        })
        let slowFooter: ViewState<SectionHeaderFooterTextView> = .cellType(hash: "sync_slow_footer", binder: { view in
            view.bind(title: slowText, topMargin: RestoreOptionsTheme.cellBigMargin, bottomMargin: RestoreOptionsTheme.separatorBottomMargin)
        }, dynamicHeight: { _ in
            return SectionHeaderFooterTextView.textHeight(forContainerWidth: width, text: slowText, font: AppTheme.footerTextFont) + footerMargins
        })
        sections.append(Section(id: "fast", footerState: slowFooter, rows: [slowRow]))

        return sections
    }

}

extension RestoreOptionsViewController: IRestoreOptionsView {
}
