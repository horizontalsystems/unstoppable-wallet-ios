import UIKit
import SnapKit

class TransactionCurrenciesHeaderView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    static let headerHeight: CGFloat = 40

    var filters = [Wallet?]()
    var collectionView: UICollectionView
    var onSelectWallet: ((Wallet?) -> ())?

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        backgroundColor = .themeNavigationBarBackground

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: layoutMargins.left * 2, bottom: 0, right: layoutMargins.right * 2)
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: TransactionsCurrencyCell.self)

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: TransactionsCurrencyCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TransactionsCurrencyCell {
            cell.bind(title: title(index: indexPath.item), selected: collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        TransactionsCurrencyCell.size(for: title(index: indexPath.item))
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
        onSelectWallet?(filters[indexPath.item])
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func reload(filters: [Wallet?]) {
        self.filters = filters
        collectionView.reloadData()

        if filters.count > 0 {
            collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        }
    }

    private func title(index: Int) -> String {
        let title = filters[index]?.coin.code ?? "transactions.filter_all".localized
        return title.uppercased()
    }

}
