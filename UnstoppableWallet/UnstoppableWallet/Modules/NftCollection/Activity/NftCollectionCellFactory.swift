import UIKit
import SectionsTableView
import ComponentKit

class NftCollectionCellFactory {
    weak var parentNavigationController: UINavigationController?

    private func openAsset(viewItem: NftActivityViewModel.EventViewItem, imageRatio: CGFloat) {
        let module = NftAssetModule.viewController(collectionUid: viewItem.collectionUid, contractAddress: viewItem.contractAddress, tokenId: viewItem.tokenId, imageRatio: imageRatio)
        parentNavigationController?.pushViewController(module, animated: true)
    }
}

extension NftCollectionCellFactory: INftActivityCellFactory {
    func row(tableView: UIKit.UITableView, viewItem: NftActivityViewModel.EventViewItem, index: Int, onReachBottom: (() -> ())? = nil) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .multiText, .multiText],
                tableView: tableView,
                id: "event-\(index)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .transparent, isLast: onReachBottom != nil)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.imageUrl, placeholder: nil)
                        component.imageView.cornerRadius = .cornerRadius4
                        component.imageView.backgroundColor = .themeSteel20
                        component.imageView.contentMode = .scaleAspectFill
                    }

                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.type
                        component.subtitle.text = viewItem.date
                    }

                    cell.bind(index: 2) { (component: MultiTextComponent) in
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
                },
                actionWithCell: { [weak self] cell in
                    let component: ImageComponent? = cell.component(index: 0)
                    self?.openAsset(viewItem: viewItem, imageRatio: component?.imageRatio ?? 1)
                }
        )
    }
}
