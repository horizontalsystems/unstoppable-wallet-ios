import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import CollectionViewCenteredFlowLayout

class MnemonicPhraseCell: BaseThemeCell {
    private static let backgroundStyle: BaseThemeCell.BackgroundStyle = .bordered
    private static let horizontalPadding: CGFloat = .margin16
    private static let verticalPadding: CGFloat = .margin24
    private static let itemSpacing: CGFloat = .margin16
    private static let lineSpacing: CGFloat = .margin16

    private var words = [String]()

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: CollectionViewCenteredFlowLayout())
    private let hintText = TextComponent()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        set(backgroundStyle: Self.backgroundStyle, cornerRadius: .cornerRadius24, isFirst: true, isLast: true)

        wrapperView.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalPadding)
            maker.top.bottom.equalToSuperview().inset(Self.verticalPadding)
        }

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isUserInteractionEnabled = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MnemonicWordCell.self, forCellWithReuseIdentifier: String(describing: MnemonicWordCell.self))

        wrapperView.addSubview(hintText)
        hintText.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.bottom.equalToSuperview()
        }

        hintText.textAlignment = .center
        hintText.numberOfLines = 0
        hintText.font = .subhead2
        hintText.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MnemonicPhraseCell {

    func set(state: State) {
        switch state {
        case .hidden(let hint):
            collectionView.isHidden = true
            hintText.isHidden = false

            hintText.text = hint
        case .visible(let words):
            hintText.isHidden = true
            collectionView.isHidden = false

            self.words = words
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

}

extension MnemonicPhraseCell: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        words.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: MnemonicWordCell.self), for: indexPath)
    }

}

extension MnemonicPhraseCell: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MnemonicWordCell {
            let index = indexPath.item
            cell.bind(index: index + 1, word: words[index])
        }
    }

}

extension MnemonicPhraseCell: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = indexPath.item
        return MnemonicWordCell.size(index: index + 1, word: words[index])
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Self.itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Self.lineSpacing
    }

}

extension MnemonicPhraseCell {

    static func height(containerWidth: CGFloat, words: [String]) -> CGFloat {
        let collectionWidth = containerWidth - margin(backgroundStyle: backgroundStyle).width - horizontalPadding * 2

        var lines = 1
        var lineHeight: CGFloat = 0
        var remainingWidth = collectionWidth

        for (index, word) in words.enumerated() {
            let size = MnemonicWordCell.size(index: index + 1, word: word)

            lineHeight = max(lineHeight, size.height)

            if size.width <= remainingWidth {
                remainingWidth = remainingWidth - size.width - itemSpacing
            } else {
                remainingWidth = collectionWidth - size.width - itemSpacing
                lines += 1
            }
        }

        let collectionHeight = CGFloat(lines) * lineHeight + CGFloat(lines - 1) * lineSpacing
        return collectionHeight + verticalPadding * 2
    }

}

extension MnemonicPhraseCell {

    enum State {
        case hidden(hint: String)
        case visible(words: [String])
    }

}
