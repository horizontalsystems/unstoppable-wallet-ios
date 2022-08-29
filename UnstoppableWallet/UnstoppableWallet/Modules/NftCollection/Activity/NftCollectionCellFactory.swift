import UIKit
import SectionsTableView
import ComponentKit

class NftCollectionCellFactory: NftAssetCellFactory {
    override func actionWithCell(viewItem: NftActivityViewModel.EventViewItem) -> ((BaseThemeCell) -> ())? {
        { [weak self] cell in
            let component: ImageComponent? = cell.component(index: 0)
            self?.openAsset(viewItem: viewItem, imageRatio: component?.imageRatio ?? 1)
        }
    }

    override func cellElement(viewItem: NftActivityViewModel.EventViewItem) -> CellBuilderNew.CellElement {
        .hStack([
            image(viewItem: viewItem),
            super.cellElement(viewItem: viewItem)
        ])
    }

    private func image(viewItem: NftActivityViewModel.EventViewItem) -> CellBuilderNew.CellElement {
        .image24 { component in
            component.setImage(urlString: viewItem.imageUrl, placeholder: nil)
            component.imageView.cornerRadius = .cornerRadius4
            component.imageView.layer.cornerCurve = .continuous
            component.imageView.backgroundColor = .themeSteel20
            component.imageView.contentMode = .scaleAspectFill
        }
    }

    private func openAsset(viewItem: NftActivityViewModel.EventViewItem, imageRatio: CGFloat) {
//        let module = NftAssetModule.viewController(collectionUid: viewItem.collectionUid, contractAddress: viewItem.contractAddress, tokenId: viewItem.tokenId, imageRatio: imageRatio)
//        parentNavigationController?.pushViewController(module, animated: true)
    }
}
