import UIKit
import SectionsTableView
import ThemeKit

class DerivationSettingsViewController: ThemeViewController {
    private let delegate: IDerivationSettingsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [DerivationSettingSectionViewItem]()

    init(delegate: IDerivationSettingsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "blockchain_settings.title".localized

        tableView.registerCell(forClass: DerivationSettingCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
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

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func section(viewItem: DerivationSettingSectionViewItem, index: Int) -> SectionProtocol {
        Section(
                id: viewItem.coinName,
                headerState: header(text: viewItem.coinName),
                footerState: .margin(height: .margin8x),
                rows: viewItem.items.enumerated().map { rowIndex, rowViewItem -> RowProtocol in
                    row(viewItem: rowViewItem, sectionIndex: index, rowIndex: rowIndex, last: rowIndex == viewItem.items.count - 1)
                }
        )
    }

    private func row(viewItem: DerivationSettingViewItem, sectionIndex: Int, rowIndex: Int, last: Bool) -> RowProtocol {
        Row<DerivationSettingCell>(
                id: viewItem.title,
                hash: "\(viewItem.selected)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.bind(
                            title: viewItem.title,
                            subtitle: viewItem.subtitle,
                            selected: viewItem.selected,
                            last: last
                    )
                },
                action: { [weak self] _ in
                    self?.delegate.onSelect(chainIndex: sectionIndex, settingIndex: rowIndex)
                }
        )
    }

}

extension DerivationSettingsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.enumerated().map { index, viewItem in
            section(viewItem: viewItem, index: index)
        }
    }

}

extension DerivationSettingsViewController: IDerivationSettingsView {

    func set(viewItems: [DerivationSettingSectionViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

}
