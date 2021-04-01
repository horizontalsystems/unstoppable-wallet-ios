import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import PinKit

class ShowKeyViewController: ThemeViewController {
    private let horizontalMargin: CGFloat = .margin16

    private let viewModel: ShowKeyViewModel
    private let disposeBag = DisposeBag()

    private let descriptionView = HighlightedDescriptionView()
    private let showButton = ThemeButton()

    private let collectionView: UICollectionView
    private let closeButtonHolder = BottomGradientHolder()
    private let closeButton = ThemeButton()

    init(viewModel: ShowKeyViewModel) {
        self.viewModel = viewModel

        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "show_key.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(CGFloat.margin12)
        }

        descriptionView.text = "show_key.description".localized

        view.addSubview(showButton)
        showButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        showButton.apply(style: .primaryYellow)
        showButton.setTitle("show_key.button_show".localized, for: .normal)
        showButton.addTarget(self, action: #selector(onTapShowButton), for: .touchUpInside)

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        collectionView.isHidden = true
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: .margin12, left: 0, bottom: .margin32, right: 0)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(BackupWordsCell.self, forCellWithReuseIdentifier: String(describing: BackupWordsCell.self))

        view.addSubview(closeButtonHolder)
        closeButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(collectionView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        closeButtonHolder.isHidden = true

        closeButtonHolder.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        closeButton.apply(style: .primaryYellow)
        closeButton.setTitle("button.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(onTapCloseButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.showKeySignal) { [weak self] in self?.showKey() }
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    @objc private func onTapShowButton() {
        viewModel.onTapShow()
    }

    private func openUnlock() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin48, right: 0)
        let viewController = App.shared.pinKit.unlockPinModule(delegate: self, biometryUnlockMode: .disabled, insets: insets, cancellable: true, autoDismiss: true)
        present(viewController, animated: true)
    }

    private func showKey() {
        navigationItem.rightBarButtonItem = nil

        showButton.isHidden = true
        descriptionView.isHidden = true

        collectionView.isHidden = false
        closeButtonHolder.isHidden = false
    }

    private func words(for index: Int) -> [String] {
        Array(viewModel.words.suffix(from: index * BackupWordsCell.maxWordsCount).prefix(BackupWordsCell.maxWordsCount))
    }

}

extension ShowKeyViewController: IUnlockDelegate {

    func onUnlock() {
        viewModel.onUnlock()
    }

    func onCancelUnlock() {
    }

}

extension ShowKeyViewController: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.words.count / BackupWordsCell.maxWordsCount + (viewModel.words.count % BackupWordsCell.maxWordsCount != 0 ? 1 : 0)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BackupWordsCell.self), for: indexPath)
    }

}

extension ShowKeyViewController: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BackupWordsCell {
            cell.bind(startIndex: indexPath.row * BackupWordsCell.maxWordsCount + 1, words: words(for: indexPath.row))
        }
    }

}

extension ShowKeyViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.width / 2 - horizontalMargin, height: BackupWordsCell.heightFor(words: words(for: indexPath.row)))
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: horizontalMargin, bottom: 0, right: horizontalMargin)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        CGFloat.margin24
    }

}
