import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import CollectionViewCenteredFlowLayout

class BackupMnemonicWordsCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin16
    private static let itemSpacing: CGFloat = .margin12
    private static let lineSpacing: CGFloat = .margin16

    private var viewItems = [BackupVerifyWordsViewModel.WordViewItem]()
    private var onTap: ((Int) -> ())?

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: CollectionViewCenteredFlowLayout())

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalPadding)
            maker.top.bottom.equalToSuperview()
        }

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BackupMnemonicWordCell.self, forCellWithReuseIdentifier: String(describing: BackupMnemonicWordCell.self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension BackupMnemonicWordsCell {

    func set(viewItems: [BackupVerifyWordsViewModel.WordViewItem], onTap: @escaping (Int) -> ()) {
        self.viewItems = viewItems
        self.onTap = onTap

        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

}

extension BackupMnemonicWordsCell: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BackupMnemonicWordCell.self), for: indexPath)
    }

}

extension BackupMnemonicWordsCell: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BackupMnemonicWordCell {
            let index = indexPath.item

            cell.bind(viewItem: viewItems[index]) { [weak self] in
                self?.onTap?(index)
            }
        }
    }

}

extension BackupMnemonicWordsCell: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        BackupMnemonicWordCell.size(word: viewItems[indexPath.item].text)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Self.itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Self.lineSpacing
    }

}

extension BackupMnemonicWordsCell {

    static func height(containerWidth: CGFloat, viewItems: [BackupVerifyWordsViewModel.WordViewItem]) -> CGFloat {
        let collectionWidth = containerWidth - horizontalPadding * 2

        var lines = 1
        var lineHeight: CGFloat = 0
        var remainingWidth = collectionWidth

        for viewItem in viewItems {
            let size = BackupMnemonicWordCell.size(word: viewItem.text)

            lineHeight = max(lineHeight, size.height)

            if size.width <= remainingWidth {
                remainingWidth = remainingWidth - size.width - itemSpacing
            } else {
                remainingWidth = collectionWidth - size.width - itemSpacing
                lines += 1
            }
        }

        let collectionHeight = CGFloat(lines) * lineHeight + CGFloat(lines - 1) * lineSpacing
        return collectionHeight
    }

}
