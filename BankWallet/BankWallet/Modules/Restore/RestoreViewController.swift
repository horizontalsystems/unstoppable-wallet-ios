import UIKit
import RxSwift

class RestoreViewController: KeyboardObservingViewController {

    let delegate: IRestoreViewDelegate

    @IBOutlet weak var wordsCollectionView: UICollectionView?
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint?

    let restoreDescription = "restore.description".localized

    var words = [String](repeating: "", count: 12)

    var onReturnSubject = PublishSubject<IndexPath>()

    var firstLaunch = true

    init(delegate: IRestoreViewDelegate) {
        self.delegate = delegate

        super.init(nibName: String(describing: RestoreViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "restore.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "restore.restore".localized, style: .plain, target: self, action: #selector(restoreDidTap))

        wordsCollectionView?.registerCell(forClass: RestoreWordCell.self)
        wordsCollectionView?.registerView(forClass: DescriptionCollectionHeader.self, flowSupplementaryKind: .header)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async  {
            self.becomeResponder(at: IndexPath(item: 0, section: 0))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func cancelDidTap() {
        view.endEditing(true)
        delegate.cancelDidClick()
    }

    @objc func restoreDidTap() {
        delegate.restoreDidClick(withWords: words)
    }

    override func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIViewAnimationOptions, completion: (() -> ())?) {
        var insets: UIEdgeInsets = wordsCollectionView?.contentInset ?? .zero
        insets.bottom = keyboardHeight + RestoreTheme.listBottomMargin
        wordsCollectionView?.contentInset = insets
    }

}

extension RestoreViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (wordsCollectionView?.bounds.width ?? view.bounds.width) - RestoreTheme.interItemSpacing
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
        let width = wordsCollectionView?.bounds.width ?? view.bounds.width
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
        words[indexPath.item] = word?.trimmingCharacters(in: .whitespaces) ?? ""
    }

}

extension RestoreViewController: IRestoreView {

    func showInvalidWordsError() {
        HudHelper.instance.showError(title: "restore.validation_failed".localized)
    }

    func showConfirmAlert() {
        BackupConfirmationAlertModel.show(from: self) { [weak self] success in
            if success {
                self?.delegate.didConfirm(words: self?.words ?? [])
            }
        }
    }

}
