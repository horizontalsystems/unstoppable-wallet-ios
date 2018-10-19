import UIKit
import SnapKit

class TransactionCurrenciesHeaderView: UIVisualEffectView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    var filters = [TransactionFilterItem]()
    var collectionView: UICollectionView
    var onSelectCoin: ((Coin?) -> ())?

    let separatorView = UIView()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(effect: UIBlurEffect(style: AppTheme.blurStyle))

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: layoutMargins.left * 2, bottom: 0, right: layoutMargins.right * 2)
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColor = .clear

        collectionView.registerCell(forClass: TransactionsCurrencyCell.self)

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        contentView.addSubview(separatorView)
        separatorView.backgroundColor = TransactionsTheme.headerSeparatorBackground
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: TransactionsCurrencyCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TransactionsCurrencyCell {
            cell.bind(transactionFilter: filters[indexPath.item], selected: collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TransactionsCurrencyCell.size(for: filters[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TransactionsFilterTheme.spacing
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectCoin?(filters[indexPath.item].coin)
    }

    func reload(filters: [TransactionFilterItem]) {
        self.filters = filters
        collectionView.reloadData()
        if filters.count > 0 {
            collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        }
    }

}
