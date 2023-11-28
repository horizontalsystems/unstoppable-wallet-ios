import MarketKit
import SnapKit
import UIKit

class MarketOverviewCategoryCell: UITableViewCell {
    static let cellHeight: CGFloat = 316

    var onSelect: ((String) -> Void)?

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    var viewItems = [MarketOverviewCategoryViewModel.ViewItem]() {
        didSet {
            collectionView.reloadData()
        }
    }

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.backgroundColor = .clear

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MarketDiscoveryCell.self, forCellWithReuseIdentifier: String(describing: MarketDiscoveryCell.self))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MarketOverviewCategoryCell: UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        viewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MarketDiscoveryCell.self), for: indexPath)
    }
}

extension MarketOverviewCategoryCell: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MarketDiscoveryCell {
            cell.set(viewItem: viewItems[indexPath.item])
        }
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(viewItems[indexPath.item].uid)
    }
}

extension MarketOverviewCategoryCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        CGSize(width: (collectionView.width - .margin16 * 2 - .margin12) / 2, height: MarketDiscoveryCell.cellHeight)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        .margin12
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        .margin12
    }
}
