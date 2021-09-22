import UIKit
import SnapKit
import ComponentKit

extension FilterHeaderView {
    enum ViewItem {
        case all
        case item(title: String)
    }
}

class FilterHeaderView: UITableViewHeaderFooterView {
    static var height: CGFloat = .heightSingleLineCell

    private var filters = [ViewItem]()
    private let layout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView
    private var contentWidth: CGFloat = 0
    private var buttonStyle: ThemeButtonStyle

    private let selectedView = UIView()
    private let animationDuration: TimeInterval

    var onSelect: ((Int) -> ())?

    var headerHeight: CGFloat {
        filters.isEmpty ? 0 : Self.height
    }

    init(buttonStyle: ThemeButtonStyle) {
        self.buttonStyle = buttonStyle

        layout.scrollDirection = .horizontal
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        animationDuration = buttonStyle == .tab ? 0.2 : .themeAnimationDuration

        super.init(reuseIdentifier: nil)

        clipsToBounds = true

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

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

        let separator = UIView()
        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separator.backgroundColor = UIColor.themeSteel10

        addSubview(selectedView)
        selectedView.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().offset(2)
            maker.leading.equalToSuperview()
            maker.height.equalTo(4)
        }

        selectedView.cornerRadius = 2
        selectedView.backgroundColor = buttonStyle == .tab ? .themeJacob : .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func title(index: Int) -> String {
        switch filters[index] {
        case .all: return "transactions.filter_all".localized
        case .item(let title): return title
        }
    }

    private func calculateContentWidth() {
        contentWidth = 0
        for i in 0..<filters.count {
            contentWidth += FilterHeaderCell.size(for: title(index: i), buttonStyle: buttonStyle).width + layout.minimumInteritemSpacing
        }
    }

    func reload(filters: [ViewItem]) {
        self.filters = filters
        calculateContentWidth()
        collectionView.reloadData()

        if filters.count > 0 {
            collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        }
    }

    func select(index: Int) {
        let selectedItem = IndexPath(item: index, section: 0)

        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems,      // check already selected item
           indexPathsForSelectedItems.contains(selectedItem) {
            return
        }

        if filters.count > index {
            collectionView.selectItem(at: selectedItem, animated: false, scrollPosition: .left)
        }
    }

}

extension FilterHeaderView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FilterHeaderCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? FilterHeaderCell {
            let selected = collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false
            cell.bind(title: title(index: indexPath.item), selected: selected, buttonStyle: buttonStyle)

            if selected {
                layoutSelectedView(toCell: cell)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = contentWidth + collectionView.contentInset.left * 2 + layout.minimumInteritemSpacing
        if buttonStyle == .tab, width < bounds.width {
            let width = (bounds.width - collectionView.contentInset.left * 2 - CGFloat(filters.count - 1) * layout.minimumInteritemSpacing) / CGFloat(filters.count)
            return CGSize(width: width, height: FilterHeaderCell.height(buttonStyle: buttonStyle))
        }

        return FilterHeaderCell.size(for: title(index: indexPath.item), buttonStyle: buttonStyle)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        .margin8
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first, selectedIndexPath == indexPath {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)

        let selectedCell = collectionView.cellForItem(at: indexPath)
        layoutSelectedView(toCell: selectedCell)

        UIView.animate(withDuration: animationDuration, animations: {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.layoutSubviews()
        })
    }

    private func layoutSelectedView(toCell cell: UICollectionViewCell?) {
        selectedView.snp.remakeConstraints { maker in
            maker.bottom.equalToSuperview().offset(2)
            maker.leading.trailing.equalTo((cell?.contentView)!)
            maker.height.equalTo(4)
        }
    }

}
