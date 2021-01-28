import UIKit
import SnapKit

class MarketDiscoveryFilterHeaderView: UITableViewHeaderFooterView {
    public static var headerHeight: CGFloat = 118

    private var filters = [MarketFilterViewItem]()

    private let collectionView: UICollectionView

    var onSelect: ((Int) -> ())?

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(reuseIdentifier: nil)

        backgroundColor = .themeNavigationBarBackground

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: .margin12, left: .margin16, bottom: .margin12, right: .margin16)
        collectionView.allowsMultipleSelection = false
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

    func reload(filters: [MarketFilterViewItem]) {
        self.filters = filters
        collectionView.reloadData()
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
        let selected = collectionView.indexPathsForSelectedItems?.first?.item == indexPath.item
        return FilterCard.size(item: filters[indexPath.item], selected: selected)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin12
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

}
