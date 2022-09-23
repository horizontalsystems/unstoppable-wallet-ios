import ComponentKit
import SectionsTableView
import UIKit

class NftAssetCellFactory {
    weak var parentNavigationController: UINavigationController?

    func action(viewItem: NftActivityViewModel.EventViewItem) -> (() -> Void)? { nil }

    func cellElement(viewItem: NftActivityViewModel.EventViewItem) -> CellBuilderNew.CellElement {
        .vStackCentered([
            line(font: .body, textColor: .themeLeah, title: viewItem.type, subtitle: viewItem.coinPrice),
            .margin(1),
            line(font: .subhead2, textColor: .themeGray, title: viewItem.date, subtitle: viewItem.fiatPrice),
        ])
    }

    private func line(font: UIFont, textColor: UIColor, title: String?, subtitle: String?) -> CellBuilderNew.CellElement {
        .hStack([
            .text { component in
                component.font = font
                component.textColor = textColor
                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                component.text = title
            },
            .text { component in
                component.font = font
                component.textColor = textColor
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
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .transparent, isLast: onReachBottom != nil)
                onReachBottom?()
            },
            action: action(viewItem: viewItem)
        )
    }
}
