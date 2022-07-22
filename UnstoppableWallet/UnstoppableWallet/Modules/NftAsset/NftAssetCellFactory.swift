import ComponentKit
import SectionsTableView
import UIKit

class NftAssetCellFactory {
    weak var parentNavigationController: UINavigationController?

    func actionWithCell(viewItem: NftActivityViewModel.EventViewItem) -> ((BaseThemeCell) -> Void)? { nil }

    func cellElement(viewItem: NftActivityViewModel.EventViewItem) -> CellBuilderNew.CellElement {
        .vStackCentered([
            line(style: .b2, title: viewItem.type, subtitle: viewItem.coinPrice),
            .margin(1),
            line(style: .d1, title: viewItem.date, subtitle: viewItem.fiatPrice),
        ])
    }

    private func line(style: TextComponent.Style, title: String?, subtitle: String?) -> CellBuilderNew.CellElement {
        .hStack([
            .text { component in
                component.set(style: style)
                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                component.text = title
            },
            .text { component in
                component.set(style: style)
                component.textAlignment = .right
                component.text = subtitle
            },
        ])
    }
}

extension NftAssetCellFactory: INftActivityCellFactory {
    func row(tableView: UIKit.UITableView, viewItem: NftActivityViewModel.EventViewItem, index: Int, onReachBottom: (() -> Void)? = nil) -> RowProtocol {
        CellBuilderNew.row(
            rootElement: cellElement(viewItem: viewItem),
            tableView: tableView,
            id: "event-\(index)",
            height: .heightDoubleLineCell,
            autoDeselect: actionWithCell != nil,
            bind: { [weak self] cell in
                cell.set(backgroundStyle: .transparent, isLast: onReachBottom != nil)
                onReachBottom?()
            },
            actionWithCell: actionWithCell(viewItem: viewItem)
        )
    }
}
