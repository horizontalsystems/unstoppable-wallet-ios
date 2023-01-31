import UIKit
import SectionsTableView
import ComponentKit

class NftCollectionCellFactory: NftAssetCellFactory {
    private let providerCollectionUid: String

    init(providerCollectionUid: String) {
        self.providerCollectionUid = providerCollectionUid
    }

    override func action(viewItem: NftActivityViewModel.EventViewItem) -> (() -> ())? {
        guard let nftUid = viewItem.nftUid else {
            return nil
        }

        return { [weak self] in
            self?.openAsset(nftUid: nftUid)
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

    private func openAsset(nftUid: NftUid) {
        let module = NftAssetModule.viewController(providerCollectionUid: providerCollectionUid, nftUid: nftUid)
        parentNavigationController?.pushViewController(module, animated: true)
    }
}
