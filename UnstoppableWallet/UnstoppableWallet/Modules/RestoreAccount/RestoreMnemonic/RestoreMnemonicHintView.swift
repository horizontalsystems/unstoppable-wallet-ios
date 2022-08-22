import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import AlignedCollectionViewFlowLayout

class RestoreMnemonicHintView: UIView {
    private static let horizontalPadding: CGFloat = .margin16
    private static let itemSpacing: CGFloat = .margin12

    var words = [String]()

    private let emptyView = UIImageView()
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: AlignedCollectionViewFlowLayout(horizontalAlignment: .leading))

    var onSelectWord: ((String) -> ())?

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeTyler

        let separator = UIView()

        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separator.backgroundColor = .themeSteel10

        addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize24)
        }

        addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalPadding)
            maker.top.bottom.equalToSuperview()
        }

        emptyView.isHidden = false
        emptyView.image = UIImage(named: "more_24")

        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false

        // actually all words are set to collection view for now, that is why scroll should be disabled
        collectionView.isScrollEnabled = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RestoreMnemonicHintCell.self, forCellWithReuseIdentifier: String(describing: RestoreMnemonicHintCell.self))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension RestoreMnemonicHintView {

    func set(words: [String]) {
        self.words = words

        emptyView.isHidden = !words.isEmpty
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

}

extension RestoreMnemonicHintView: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        words.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: RestoreMnemonicHintCell.self), for: indexPath)
    }

}

extension RestoreMnemonicHintView: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? RestoreMnemonicHintCell {
            let word = words[indexPath.item]
            cell.bind(word: word) { [weak self] in
                self?.onSelectWord?(word)
            }
        }
    }

}

extension RestoreMnemonicHintView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        RestoreMnemonicHintCell.size(word: words[indexPath.item])
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Self.itemSpacing
    }

}
