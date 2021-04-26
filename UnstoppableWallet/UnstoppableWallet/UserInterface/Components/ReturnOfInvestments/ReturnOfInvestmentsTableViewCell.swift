import UIKit
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import ComponentKit

class ReturnOfInvestmentsTableViewCell: BaseThemeCell {
    private let disposeBag = DisposeBag()

    private let sideMargin: CGFloat = .margin16
    private static let gridRowHeight: CGFloat = .heightSingleLineCell

    private let collectionView: UICollectionView

    private var viewItems = [[CoinPageViewModel.ReturnOfInvestmentsViewItem]]()

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

    func bind(viewItems: [[CoinPageViewModel.ReturnOfInvestmentsViewItem]]) {
        self.viewItems = viewItems
        collectionView.reloadData()
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
        let viewItem = viewItems[indexPath.section][indexPath.item]
        switch viewItem {
        case .title(let title), .subtitle(let title), .content(let title): bindSideCell(title: title, type: viewItem, cell: cell, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
        case .value(let amount): bindContentCell(amount: amount, cell: cell, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let minWidth = collectionView.frame.size.width / 4
        let currentWidth = collectionView.frame.size.width / CGFloat(viewItems[indexPath.section].count)

        return CGSize(width: max(minWidth, currentWidth), height: Self.gridRowHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func bindSideCell(title: String, type: CoinPageViewModel.ReturnOfInvestmentsViewItem, cell: UICollectionViewCell, horizontalFirst: Bool, verticalFirst: Bool) {
        if let cell = cell as? ReturnOfInvestmentsSideCollectionViewCell {
            cell.set(viewItem: type, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
            cell.title = title
        }
    }

    private func bindContentCell(amount: Decimal?, cell: UICollectionViewCell, horizontalFirst: Bool, verticalFirst: Bool) {
        if let cell = cell as? ReturnOfInvestmentsContentCollectionViewCell {
            cell.set(value: amount, horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)
        }
    }

}

extension ReturnOfInvestmentsTableViewCell {

    static func height(viewItems: [[CoinPageViewModel.ReturnOfInvestmentsViewItem]]) -> CGFloat {
        CGFloat(viewItems.count) * gridRowHeight
    }

}
