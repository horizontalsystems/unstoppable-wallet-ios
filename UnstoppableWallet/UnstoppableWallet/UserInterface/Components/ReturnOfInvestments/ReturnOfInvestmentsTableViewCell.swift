import UIKit
import SnapKit
import ThemeKit

class ReturnOfInvestmentsTableViewCell: BaseThemeCell {
    static let sideMargin: CGFloat = .margin16
    static let gridRowHeight: CGFloat = .heightSingleLineCell

    private let collectionView: UICollectionView

    private var viewItems = [[CellType]]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        wrapperView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = false
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false

        collectionView.registerCell(forClass: ReturnOfInvestmentsSideCollectionViewCell.self)
        collectionView.registerCell(forClass: ReturnOfInvestmentsContentCollectionViewCell.self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(items: [[CellType]]) {
        viewItems = items
        collectionView.reloadData()
    }

    func cellHeight(rowCount: Int) -> CGFloat {
        CGFloat(rowCount) * ReturnOfInvestmentsTableViewCell.gridRowHeight
    }

}

extension ReturnOfInvestmentsTableViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewItems[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch viewItems[indexPath.section][indexPath.item] {
        case .title, .subtitle, .content: return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReturnOfInvestmentsSideCollectionViewCell.self), for: indexPath)
        case .value: return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ReturnOfInvestmentsContentCollectionViewCell.self), for: indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let verticalFirst = indexPath.section == 0 || indexPath.section == 1
        let horizontalFirst = indexPath.item == 0
        let cellType = viewItems[indexPath.section][indexPath.item]
        switch cellType {
        case .title(let title), .subtitle(let title), .content(let title): bindSideCell(title: title, type: cellType, cell: cell, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
        case .value(let amount): bindContentCell(amount: amount, cell: cell, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.size.width / 4, height: ReturnOfInvestmentsTableViewCell.gridRowHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func bindSideCell(title: String, type: CellType, cell: UICollectionViewCell, horizontalFirst: Bool, verticalFirst: Bool) {
        if let cell = cell as? ReturnOfInvestmentsSideCollectionViewCell {
            cell.set(cellType: type, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
            cell.title = title
        }
    }

    private func bindContentCell(amount: Decimal, cell: UICollectionViewCell, horizontalFirst: Bool, verticalFirst: Bool) {
        if let cell = cell as? ReturnOfInvestmentsContentCollectionViewCell {
            cell.set(value: amount, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
        }
    }

}

extension ReturnOfInvestmentsTableViewCell {

    enum CellType {
        case title(String)
        case subtitle(String)
        case content(String)
        case value(Decimal)

        var font: UIFont? {
            switch self {
            case .title: return .subhead1
            case .subtitle: return .caption
            case .content: return .caption
            case .value: return nil
            }
        }

        var color: UIColor? {
            switch self {
            case .title: return .themeOz
            case .subtitle: return .themeBran
            case .content: return .themeGray
            case .value: return nil
            }
        }

        var backgroundColor: UIColor? {
            switch self {
            case .title, .subtitle: return .themeLawrence
            case .content, .value: return .themeBlake
            }
        }

    }
}
