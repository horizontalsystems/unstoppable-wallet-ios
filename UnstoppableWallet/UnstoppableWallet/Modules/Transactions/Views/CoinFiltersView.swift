import UIKit
import SnapKit

class CoinFiltersView: UITableViewHeaderFooterView {
    static var height: CGFloat = .heightSingleLineCell

    private var filters = [String]()
    private var selectedIndex: Int? = nil
    private let collectionView: UICollectionView

    var onSelect: ((Int) -> ())?
    var onDeselect: ((Int) -> ())?

    var headerHeight: CGFloat {
        filters.isEmpty ? 0 : Self.height
    }

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: .margin8, left: .margin16, bottom: .margin8, right: .margin16)
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: FilterHeaderCell.self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func reload(filters: [String]) {
        self.filters = filters
        collectionView.reloadData()
    }

}

extension CoinFiltersView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterHeaderCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? FilterHeaderCell {
            cell.bind(title: filters[indexPath.item], selected: collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        FilterHeaderCell.size(for: filters[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin8
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndex == indexPath.item {
            onDeselect?(indexPath.item)
            selectedIndex = nil
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            onSelect?(indexPath.item)
            selectedIndex = indexPath.item
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }

}
