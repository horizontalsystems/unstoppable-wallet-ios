import UIKit
import SectionsTableView
import ComponentKit

class NftCollectionCellFactory: NftAssetCellFactory {

    override func action(viewItem: NftActivityViewModel.EventViewItem) -> (() -> ())? {
        { [weak self] in
            self?.openAsset(viewItem: viewItem)
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

    private func openAsset(viewItem: NftActivityViewModel.EventViewItem) {
        let module = NftAssetModule.viewController(providerCollectionUid: viewItem.providerCollectionUid, nftUid: viewItem.nftUid)
        parentNavigationController?.pushViewController(module, animated: true)
    }
}
