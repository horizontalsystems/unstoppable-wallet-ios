import Foundation
import UIKit

class MarketTickerDataSource: ITickerCollectionDataSource {

    var count: Int {
        items.count
    }

    private var items = [MarketTickerViewModel.ViewItem]()

    func set(items: [MarketTickerViewModel.ViewItem]) {
        self.items = items
    }

    func size(forItemAt index: Int) -> CGSize {
        MarketTickerCollectionCell.size(viewItem: items[index])
    }

    func cell(_ collectionView: UICollectionView, forItemAt index: Int) -> UIKit.UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MarketTickerCollectionCell.self), for: IndexPath(item: index, section: 0))
    }

    func bind(_ cell: UICollectionViewCell, forItemAt index: Int) {
        if let cell = cell as? MarketTickerCollectionCell {
            cell.bind(viewItem: items[index])
        }
    }

}
