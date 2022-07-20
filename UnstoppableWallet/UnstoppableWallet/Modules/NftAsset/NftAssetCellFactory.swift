import UIKit
import SectionsTableView
import ComponentKit

class NftAssetCellFactory {
    weak var parentNavigationController: UINavigationController?
}

extension NftAssetCellFactory: INftActivityCellFactory {
    func row(tableView: UIKit.UITableView, viewItem: NftActivityViewModel.EventViewItem, index: Int, onReachBottom: (() -> ())? = nil) -> RowProtocol {
        CellBuilder.row(
                elements: [.multiText, .multiText],
                tableView: tableView,
                id: "event-\(index)",
                height: .heightDoubleLineCell,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .transparent, isLast: onReachBottom != nil)

                    cell.bind(index: 0) { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.type
                        component.subtitle.text = viewItem.date
                    }

                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.coinPrice
                        component.title.textAlignment = .right
                        component.subtitle.text = viewItem.fiatPrice
                        component.subtitle.textAlignment = .right
                    }

                    onReachBottom?()
                }
        )
    }
}
