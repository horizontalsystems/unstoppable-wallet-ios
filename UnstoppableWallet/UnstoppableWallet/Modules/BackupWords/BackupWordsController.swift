import UIKit
import SnapKit
import ThemeKit
import UIExtensions

class BackupWordsController: ThemeViewController {
    private static let horizontalMargin = CGFloat.margin4x
    private let delegate: IBackupWordsViewDelegate

    private let collectionView: UICollectionView

    private let proceedButtonHolder = BottomGradientHolder()
    private let proceedButton = ThemeButton()

    init(delegate: IBackupWordsViewDelegate) {
        self.delegate = delegate

        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        collectionView.register(BackupWordsCell.self, forCellWithReuseIdentifier: String(describing: BackupWordsCell.self))
        collectionView.register(D8CollectionCell.self, forCellWithReuseIdentifier: String(describing: D8CollectionCell.self))
        collectionView.register(D9CollectionCell.self, forCellWithReuseIdentifier: String(describing: D9CollectionCell.self))

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        title = "backup.private_key".localized

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: CGFloat.margin3x, left: 0, bottom: CGFloat.margin8x, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear

        view.addSubview(proceedButtonHolder)
        proceedButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(collectionView.snp.bottom).offset(-CGFloat.margin4x)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        proceedButtonHolder.addSubview(proceedButton)
        proceedButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        proceedButton.apply(style: .primaryYellow)
        proceedButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "button.next".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(nextDidTap), for: .touchUpInside)
    }

    private func words(for index: Int) -> [String] {
        Array(delegate.words.suffix(from: index * BackupWordsCell.maxWordsCount).prefix(BackupWordsCell.maxWordsCount))
    }

    private var wordSectionIndex: Int {
        (delegate.additionalItems.isEmpty ? 0 : 1)
    }

    @objc private func nextDidTap() {
        delegate.didTapProceed()
    }

}

extension BackupWordsController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        wordSectionIndex + 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == wordSectionIndex {
            return delegate.words.count / BackupWordsCell.maxWordsCount + (delegate.words.count % BackupWordsCell.maxWordsCount != 0 ? 1 : 0)
        }

        return delegate.additionalItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == wordSectionIndex {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BackupWordsCell.self), for: indexPath)
        }

        if delegate.additionalItems[indexPath.row].copyable {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: D9CollectionCell.self), for: indexPath)
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: D8CollectionCell.self), for: indexPath)
        }
    }

}

extension BackupWordsController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BackupWordsCell {
            cell.bind(startIndex: indexPath.row * BackupWordsCell.maxWordsCount + 1, words: words(for: indexPath.row))
        }

        if let cell = cell as? D8CollectionCell, indexPath.row < delegate.additionalItems.count {
            let item = delegate.additionalItems[indexPath.row]

            cell.set(backgroundStyle: .lawrence, bottomSeparator: true)
            cell.title = item.title.localized
            cell.value = item.value
        } else if let cell = cell as? D9CollectionCell, indexPath.row < delegate.additionalItems.count {
            let item = delegate.additionalItems[indexPath.row]

            cell.set(backgroundStyle: .lawrence, bottomSeparator: true)
            cell.title = item.title.localized
            cell.viewItem = CopyableSecondaryButton.ViewItem(value: item.value)
        }
    }

}

extension BackupWordsController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == wordSectionIndex {
            return CGSize(width: collectionView.width / 2 - Self.horizontalMargin, height: BackupWordsCell.heightFor(words: words(for: indexPath.row)))
        }
        return CGSize(width: collectionView.width, height: .heightCell48)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == wordSectionIndex {
            return UIEdgeInsets(top: 0, left: Self.horizontalMargin, bottom: 0, right: Self.horizontalMargin)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: .margin8x, right: 0)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == wordSectionIndex {
            return CGFloat.margin6x
        }
        return 0
    }

}
