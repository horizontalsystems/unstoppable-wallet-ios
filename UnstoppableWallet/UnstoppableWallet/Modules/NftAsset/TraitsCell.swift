import AlignedCollectionViewFlowLayout

import UIKit

class TraitsCell: UITableViewCell {
    private static let lineSpacing: CGFloat = .margin6
    static let horizontalInset: CGFloat = .margin16
    static let interItemSpacing: CGFloat = .margin8

    private let layout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
    private let collectionView: UICollectionView
    private var viewItems: [NftAssetOverviewViewModel.TraitViewItem] = []

    private var onSelect: ((Int) -> Void)?

    override init(style: CellStyle, reuseIdentifier: String?) {
        layout.scrollDirection = .vertical
        layout.sectionInset = .zero
        layout.minimumInteritemSpacing = Self.interItemSpacing
        layout.minimumLineSpacing = Self.lineSpacing
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Self.horizontalInset, bottom: 0, right: Self.horizontalInset)
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: TraitCell.self)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItems: [NftAssetOverviewViewModel.TraitViewItem], onSelect: @escaping (Int) -> Void) {
        self.viewItems = viewItems
        self.onSelect = onSelect

        collectionView.reloadData()
    }

    static func height(lines: Int) -> CGFloat {
        CGFloat(lines) * TraitCell.height + CGFloat(lines - 1) * lineSpacing
    }
}

extension TraitsCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        viewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: TraitCell.self), for: indexPath)
    }

    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TraitCell {
            cell.bind(viewItem: viewItems[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        TraitCell.size(for: viewItems[indexPath.item], containerWidth: collectionView.bounds.width - CGFloat.margin16 * 2)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        Self.interItemSpacing
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < viewItems.count else {
            return
        }

        let viewItem = viewItems[indexPath.item]
        onSelect?(viewItem.index)
    }
}
