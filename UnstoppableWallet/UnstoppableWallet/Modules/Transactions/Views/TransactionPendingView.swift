import UIKit
import SnapKit
import RxSwift

class TransactionPendingView: UIView {
    private let animationDelay = 200

    private let disposeBag = DisposeBag()
    private var animationDisposable: Disposable?

    private let pendingImageView = UIImageView(image: UIImage(named: "Transaction Processing Icon"))
    private let pendingLabel = UILabel()
    private let animatableStrings = ["", ".", "..", "..."]

    init() {
        super.init(frame: .zero)

        addSubview(pendingImageView)
        addSubview(pendingLabel)

        pendingImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalTo(self.pendingLabel)
        }
        pendingLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.pendingImageView.snp.trailing).offset(CGFloat.margin2x)
            maker.top.bottom.trailing.equalToSuperview()
        }

        pendingLabel.font = .subhead2
        pendingLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateText(forIndex index: Int) {
        pendingLabel.text = "transactions.pending".localized + animatableStrings[index]
    }

    func startAnimating() {
        if animationDisposable == nil {
            isHidden = false
            var index = 0
            let count = animatableStrings.count
            animationDisposable = Observable<Int>
                    .timer(.milliseconds(0), period: .milliseconds(animationDelay), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        self?.updateText(forIndex: index)
                        index += 1
                        index = index > count - 1 ? 0 : index
                    })

            animationDisposable?.disposed(by: disposeBag)
        }
    }

    func stopAnimating() {
        animationDisposable?.dispose()
    }

}
