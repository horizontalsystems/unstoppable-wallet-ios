import UIKit
import SnapKit

class MarketDiscoveryFilterHeaderView: UIView {
    public static var headerHeight: CGFloat = 108

    private var filters = [MarketFilterViewItem]()

    private let collectionView: UICollectionView

    var onSelect: ((Int?) -> ())?

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: frame)

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: .margin12, left: .margin16, bottom: .margin12, right: .margin16)
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: FilterCard.self)

        filters = MarketDiscoveryFilter.allCases.map {
            MarketFilterViewItem(icon: $0.icon, title: $0.title, description: $0.description)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension MarketDiscoveryFilterHeaderView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterCard.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? FilterCard {
            cell.bind(item: filters[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        FilterCard.size(item: filters[indexPath.item], selected: collectionView.indexPathsForSelectedItems?.first == indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin12
    }

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard collectionView.indexPathsForSelectedItems?.first == indexPath else {
            return true
        }

        UIView.animate(withDuration: .themeAnimationDuration) {
            collectionView.performBatchUpdates {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }

        handleSelect()

        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: .themeAnimationDuration) {
            collectionView.performBatchUpdates {
                collectionView.collectionViewLayout.invalidateLayout()

                // explicitly set content size in order to fix behavior of scrollToItem
                collectionView.contentSize = collectionView.collectionViewLayout.collectionViewContentSize

                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }

        handleSelect()
    }

    private func handleSelect() {
        onSelect?(collectionView.indexPathsForSelectedItems?.first?.item)
    }

}

extension MarketDiscoveryFilterHeaderView {

    func setSelected(index: Int?) {
        guard collectionView.indexPathsForSelectedItems?.first?.item != index else {
            return
        }

        let indexPath = index.map { IndexPath(item: $0, section: 0) }
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        collectionView.performBatchUpdates(nil)
    }

}
