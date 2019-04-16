import UIKit
import UIExtensions
import SnapKit
import RxSwift

class RestoreWordCell: UICollectionViewCell {

    var indexPath: IndexPath?
    var onReturnDisposable: Disposable?
    var disposeBag = DisposeBag()

    var inputField = IndexedInputField()

    override init(frame: CGRect) {
        super.init(frame: frame)

        inputField.borderWidth = 0.5
        inputField.cornerRadius = 8
        inputField.borderColor = .cryptoSteel20
        inputField.clearButtonIsHidden = true
        inputField.backgroundColor = .cryptoSteel20

        contentView.addSubview(inputField)
        inputField.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(onReturnSubject: Observable<IndexPath>, indexPath: IndexPath, index: Int, word: String, returnKeyType: UIReturnKeyType, onReturn: @escaping (() -> ()), onTextChange: @escaping ((String?) -> ())) {
         onReturnDisposable = onReturnSubject
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] indexPath in
                self?.becomeFirstResponder(indexPath: indexPath)
            })
        onReturnDisposable?.disposed(by: disposeBag)

        self.indexPath = indexPath

        inputField.indexLabel.text = "\(index)."
        inputField.onReturn = onReturn
        inputField.onTextChange = onTextChange
        inputField.textField.text = word

        inputField.textField.returnKeyType = returnKeyType
    }

    private func becomeFirstResponder(indexPath: IndexPath) {
        if let currentIndex = self.indexPath?.item, currentIndex == indexPath.item {
            inputField.textField.becomeFirstResponder()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onReturnDisposable?.dispose()
        indexPath = nil
    }

}
