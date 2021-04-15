import UIKit
import ThemeKit
import SnapKit

class MnemonicPhraseCell: UITableViewCell {
    private let horizontalMargin: CGFloat = .margin16
    private static let rowHeight: CGFloat = 20
    private static let lineSpacing: CGFloat = .margin4
    private static let sectionSpacing: CGFloat = .margin32

    private var words = [String]()

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MnemonicWordCell.self, forCellWithReuseIdentifier: String(describing: MnemonicWordCell.self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func wordIndex(indexPath: IndexPath) -> Int {
        let sectionWordCount = Self.sectionWordCount(wordCount: words.count)
        let sectionRowCount = sectionWordCount / 2

        if indexPath.row % 2 == 0 {
            return indexPath.section * sectionRowCount + indexPath.row / 2
        } else {
            return words.count / 2 + indexPath.section * sectionRowCount + indexPath.row / 2
        }
    }

}

extension MnemonicPhraseCell {

    var cellHeight: CGFloat {
        collectionView.contentSize.height
    }

    func set(words: [String]) {
        self.words = words

        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

}

extension MnemonicPhraseCell: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        Self.sectionCount(wordCount: words.count)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Self.sectionWordCount(wordCount: words.count)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MnemonicWordCell.self), for: indexPath)
    }

}

extension MnemonicPhraseCell: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MnemonicWordCell {
            let index = wordIndex(indexPath: indexPath)
            cell.bind(index: index + 1, word: words[index])
        }
    }

}

extension MnemonicPhraseCell: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.width - horizontalMargin * 2) / 2, height: Self.rowHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let bottom = section < numberOfSections(in: collectionView) - 1 ? Self.sectionSpacing : 0
        return UIEdgeInsets(top: 0, left: horizontalMargin, bottom: bottom, right: horizontalMargin)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Self.lineSpacing
    }

}

extension MnemonicPhraseCell {

    private static func sectionWordCount(wordCount: Int) -> Int {
        wordCount == 12 ? 6 : 8
    }

    private static func sectionCount(wordCount: Int) -> Int {
        wordCount / sectionWordCount(wordCount: wordCount)
    }

    static func height(wordCount: Int) -> CGFloat {
        let sectionRowCount = sectionWordCount(wordCount: wordCount) / 2
        let sectionRowsHeight = CGFloat(sectionRowCount) * rowHeight
        let sectionSpacingsHeight = CGFloat(sectionRowCount - 1) * lineSpacing
        let sectionHeight = sectionRowsHeight + sectionSpacingsHeight

        let sectionCount = Self.sectionCount(wordCount: wordCount)
        let allSectionsHeight = CGFloat(sectionCount) * sectionHeight
        let allSectionsSpacingsHeight = CGFloat(sectionCount - 1) * sectionSpacing

        return allSectionsHeight + allSectionsSpacingsHeight
    }

}
