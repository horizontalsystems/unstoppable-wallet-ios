import UIKit
import RxSwift
import SnapKit

class RestoreWordsViewController: WalletViewController {
    let disposeBag = DisposeBag()
    let delegate: IRestoreViewDelegate

    let restoreDescription = "restore.description".localized
    var words = [String](repeating: "", count: 12)

    let layout = UICollectionViewFlowLayout()
    let collectionView: UICollectionView
    var onReturnSubject = PublishSubject<IndexPath>()

    var keyboardFrameDisposable: Disposable?

    init(delegate: IRestoreViewDelegate, defaultWords: [String]) {
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        collectionView.delegate = self
        collectionView.dataSource = self

        for (index, defaultWord) in defaultWords.enumerated() {
            if index < words.count {
                words[index] = defaultWord
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "restore.title".localized

        subscribeKeyboard()

        view.addSubview(collectionView)
        collectionView.backgroundColor = .clear
        layout.minimumInteritemSpacing = RestoreTheme.interItemSpacing
        layout.minimumLineSpacing = RestoreTheme.lineSpacing
        collectionView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreTheme.collectionSideMargin)
            maker.trailing.equalToSuperview().offset(-RestoreTheme.collectionSideMargin)
            maker.top.bottom.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(restoreDidTap))

        collectionView.registerCell(forClass: RestoreWordCell.self)
        collectionView.registerView(forClass: DescriptionCollectionHeader.self, flowSupplementaryKind: .header)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if keyboardFrameDisposable == nil {
            subscribeKeyboard()
        }
        DispatchQueue.main.async  {
            self.becomeResponder(at: IndexPath(item: 0, section: 0))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func restoreDidTap() {
        view.endEditing(true)
        delegate.didTapRestore(accountType: .mnemonic(words: words, derivation: .bip44, salt: nil))
    }

    private func subscribeKeyboard() {
        keyboardFrameDisposable = NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                self?.onKeyboardFrameChange(notification)
            })
        keyboardFrameDisposable?.disposed(by: disposeBag)
    }

    func onKeyboardFrameChange(_ notification: Notification) {
        let screenKeyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let height = view.height + view.y
        let keyboardHeight = height - screenKeyboardFrame.origin.y

        let duration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let curve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue

        updateUI(keyboardHeight: keyboardHeight, duration: duration, options: UIView.AnimationOptions(rawValue: curve << 16))
    }

    func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIView.AnimationOptions, completion: (() -> ())? = nil) {
        var insets: UIEdgeInsets = collectionView.contentInset
        insets.bottom = keyboardHeight + RestoreTheme.listBottomMargin
        collectionView.contentInset = insets
    }

}

extension RestoreWordsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - RestoreTheme.interItemSpacing
        return CGSize(width: width / 2, height: RestoreTheme.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return words.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: RestoreWordCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? RestoreWordCell {
            cell.bind(onReturnSubject: onReturnSubject, indexPath: indexPath, index: indexPath.item + 1, word: words[indexPath.row], returnKeyType: indexPath.row + 1 < words.count ? .next : .done, onReturn: { [weak self] in
                self?.becomeResponder(at: IndexPath(item: indexPath.item + 1, section: 0))
            }, onTextChange: { [weak self] string in
                self?.onTextChange(word: string, at: indexPath)
            })
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: DescriptionCollectionHeader.self), for: indexPath)
        if let header = header as? DescriptionCollectionHeader {
            header.bind(text: restoreDescription)
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        let height = DescriptionCollectionHeader.height(forContainerWidth: width, text: restoreDescription)
        return CGSize(width: width, height: height)
    }

    func becomeResponder(at indexPath: IndexPath) {
        guard indexPath.row < words.count else {
            restoreDidTap()
            return
        }

        onReturnSubject.onNext(indexPath)
    }

    func onTextChange(word: String?, at indexPath: IndexPath) {
        words[indexPath.item] = word?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
    }

}
