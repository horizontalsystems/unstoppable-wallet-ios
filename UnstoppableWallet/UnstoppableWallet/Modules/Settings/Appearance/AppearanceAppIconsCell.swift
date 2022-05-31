import UIKit
import ThemeKit
import ComponentKit
import AlignedCollectionViewFlowLayout

class AppearanceAppIconsCell: BaseThemeCell {
    private static let lineSpacing: CGFloat = .margin12
    static let verticalInset: CGFloat = .margin16

    private let layout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView
    private var viewItems = [AppearanceViewModel.AppIconViewItem]()

    private var onSelect: ((Int) -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        layout.sectionInset = .zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = Self.lineSpacing
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        wrapperView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = UIEdgeInsets(top: Self.verticalInset, left: 0, bottom: Self.verticalInset, right: 0)
        collectionView.backgroundColor = .clear
        collectionView.scrollsToTop = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false

        collectionView.registerCell(forClass: AppearanceAppIconCell.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItems: [AppearanceViewModel.AppIconViewItem], onSelect: @escaping (Int) -> ()) {
        self.viewItems = viewItems
        self.onSelect = onSelect

        collectionView.reloadData()
    }

    static func height(viewItemsCount: Int) -> CGFloat {
        let lines = (viewItemsCount / 3) + (viewItemsCount % 3 == 0 ? 0 : 1)
        return CGFloat(lines) * AppearanceAppIconCell.height + CGFloat(lines - 1) * lineSpacing + 2 * verticalInset
    }

}

extension AppearanceAppIconsCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AppearanceAppIconCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? AppearanceAppIconCell {
            cell.bind(viewItem: viewItems[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: floor(collectionView.bounds.width / 3), height: AppearanceAppIconCell.height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)
    }

}
