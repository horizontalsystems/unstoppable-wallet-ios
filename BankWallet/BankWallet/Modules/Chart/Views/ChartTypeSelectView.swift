import UIKit
import SnapKit
import XRatesKit

class ChartTypeSelectView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    static let headerHeight: CGFloat = 24

    private var titles = [String]()
    private var collectionView: UICollectionView
    var onSelectIndex: ((Int) -> ())?

    private var selected: Int = 0

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        backgroundColor = .clear

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: ChartTypeCell.self)

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        titles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ChartTypeCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ChartTypeCell {
            cell.bind(title: titles[indexPath.item].uppercased(), selected: collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        ChartTypeCell.size(for: titles[indexPath.item].uppercased())
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin2x
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first, selectedIndexPath == indexPath {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectIndex?(indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func reload(titles: [String]) {
        self.titles = titles
        collectionView.reloadData()

        select(index: selected)
    }

    func select(index: Int) {
        if titles.count > selected {
            collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .left)
        }
    }

}
