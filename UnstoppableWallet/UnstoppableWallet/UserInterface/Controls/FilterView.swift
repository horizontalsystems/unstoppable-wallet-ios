
import SnapKit
import UIKit

class FilterView: UIView {
    static var height: CGFloat = .heightSingleLineCell

    private var filters = [ViewItem]()
    private let layout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView
    private var needCalculateItemWidths = true
    private var itemWidths: [CGFloat] = [] {
        didSet {
            layoutSelectedView(indexPath: collectionView.indexPathsForSelectedItems?.first ?? IndexPath(item: 0, section: 0))
        }
    }

    private var buttonStyle: SecondaryButton.Style

    private let selectedView = UIView()
    private let animationDuration: TimeInterval

    var autoDeselect: Bool = false
    var onSelect: ((Int) -> Void)?

    var headerHeight: CGFloat {
        filters.isEmpty ? 0 : Self.height
    }

    init(buttonStyle: SecondaryButton.Style, bottomSeparator: Bool = true) {
        self.buttonStyle = buttonStyle

        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        layout.minimumInteritemSpacing = .margin8
        layout.minimumLineSpacing = .margin8
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        animationDuration = buttonStyle == .tab ? 0.2 : .themeAnimationDuration

        super.init(frame: .zero)

        clipsToBounds = true
        backgroundColor = .themeNavigationBarBackground

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: FilterHeaderCell.self)

        if bottomSeparator {
            let separator = UIView()
            addSubview(separator)
            separator.snp.makeConstraints { maker in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.height.equalTo(CGFloat.heightOneDp)
            }

            separator.backgroundColor = UIColor.themeBlade
        }

        collectionView.addSubview(selectedView)
        selectedView.snp.makeConstraints { maker in
            maker.bottom.equalTo(self.snp.bottom).offset(2)
            maker.leading.equalToSuperview()
            maker.height.equalTo(4)
            maker.width.equalTo(50)
        }

        selectedView.cornerRadius = 2
        selectedView.layer.cornerCurve = .continuous
        selectedView.backgroundColor = buttonStyle == .tab ? .themeJacob : .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not implemented")
    }

    private func title(index: Int) -> String {
        switch filters[index] {
        case .all: return "transactions.filter_all".localized
        case let .item(title): return title
        }
    }

    private func equalize(count: Int, lessWidth: CGFloat, greaterWidth: CGFloat, freeSpace: CGFloat) -> (newWidth: CGFloat, freeSpace: CGFloat) {
        let count = CGFloat(count)
        let needToBeSame = (greaterWidth - lessWidth) * count
        let freeSpaceAfterEqual = freeSpace - needToBeSame
        if freeSpaceAfterEqual >= 0 {
            return (newWidth: greaterWidth, freeSpace: freeSpaceAfterEqual)
        } else {
            return (newWidth: lessWidth + freeSpace / count, freeSpace: 0)
        }
    }

    private func calculateItemWidths() {
        guard needCalculateItemWidths else {
            return
        }
        needCalculateItemWidths = false

        let interitemSpacing = CGFloat(filters.count - 1) * layout.minimumInteritemSpacing
        let width = collectionView.width - collectionView.contentInset.left - collectionView.contentInset.right - interitemSpacing

        var items = Array(0 ..< filters.count)
            .map { IndexedWidth(index: $0, width: FilterHeaderCell.width(title: title(index: $0), style: buttonStyle)) }

        let initialItemWidth = items.reduce(0) { $0 + $1.width }
        if initialItemWidth >= width { // elements can't fit into screen
            itemWidths = items.map(\.width)
            return
        }

        items.sort { $0.width < $1.width }

        var freeSpace = width - initialItemWidth
        var sameMinimalWidthItemCount = 1

        while freeSpace != 0, sameMinimalWidthItemCount < items.count {
            let (newLessWidth, newFreeSpace) = equalize(
                count: sameMinimalWidthItemCount,
                lessWidth: items[0].width,
                greaterWidth: items[sameMinimalWidthItemCount].width,
                freeSpace: freeSpace
            )

            for i in 0 ..< sameMinimalWidthItemCount {
                items[i].width = newLessWidth
            }
            freeSpace = newFreeSpace

            sameMinimalWidthItemCount += 1
        }

        if freeSpace > 0 {
            let delta = freeSpace / CGFloat(items.count)
            for i in 0 ..< items.count {
                items[i].width = items[i].width + delta
            }
        }

        itemWidths = items.sorted { $0.index < $1.index }.map(\.width)
    }

    func reload(filters: [ViewItem]) {
        guard filters != self.filters else {
            return
        }
        self.filters = filters
        needCalculateItemWidths = true
        collectionView.reloadData()

        if filters.count > 0 {
            collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        }
    }

    func select(index: Int) {
        let selectedItem = IndexPath(item: index, section: 0)

        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems, // check already selected item
           indexPathsForSelectedItems.contains(selectedItem)
        {
            return
        }

        if filters.count > index {
            collectionView.selectItem(at: selectedItem, animated: false, scrollPosition: .left)
            handleSelected(indexPath: selectedItem)
        }
    }
}

extension FilterView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterHeaderCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? FilterHeaderCell {
            let selected = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
            cell.bind(title: title(index: indexPath.item), selected: autoDeselect ? false : selected, buttonStyle: buttonStyle)
        }
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        calculateItemWidths()
        return CGSize(width: itemWidths[indexPath.item], height: .heightSingleLineCell)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        .margin8
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first, !autoDeselect, selectedIndexPath == indexPath {
            return false
        }
        return true
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)

        handleSelected(indexPath: indexPath)
    }

    private func handleSelected(indexPath: IndexPath) {
        guard collectionView.cellForItem(at: indexPath) != nil else {
            return
        }
        layoutSelectedView(indexPath: indexPath)

        UIView.animate(withDuration: animationDuration, animations: {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.collectionView.layoutSubviews()
        })

        if autoDeselect {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    private func layoutSelectedView(indexPath: IndexPath) {
        var offset: CGFloat = 0
        let spacing = collectionView(collectionView, layout: layout, minimumInteritemSpacingForSectionAt: 0)

        for i in 0 ..< indexPath.item {
            offset += itemWidths[i] + spacing
        }

        selectedView.snp.remakeConstraints { maker in
            maker.bottom.equalTo(self.snp.bottom).offset(2)
            maker.leading.equalToSuperview().offset(offset)
            maker.height.equalTo(4)
            maker.width.equalTo(itemWidths[indexPath.item])
        }
    }
}

extension FilterView {
    enum ViewItem: Equatable {
        case all
        case item(title: String)

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.item(lh), .item(rh)): return lh == rh
            case (.all, .all): return true
            default: return false
            }
        }
    }

    private class IndexedWidth {
        let index: Int
        var width: CGFloat

        init(index: Int, width: CGFloat) {
            self.index = index
            self.width = width
        }
    }
}
