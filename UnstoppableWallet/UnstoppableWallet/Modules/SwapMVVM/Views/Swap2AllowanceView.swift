import UIKit
import RxSwift
import RxCocoa

class Swap2AllowanceView: UIView {
    private var disposeBag = DisposeBag()

    private let presenter: SwapAllowancePresenter
    private let allowanceView = AdditionalDataWithLoadingView()

    public init(presenter: SwapAllowancePresenter) {
        self.presenter = presenter

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(allowanceView)
        allowanceView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        subscribeToPresenter()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func subscribeToPresenter() {
        subscribe(disposeBag, presenter.allowance) { [weak self] in self?.set(allowance: $0) }
        subscribe(disposeBag, presenter.insufficientAllowance) { [weak self] in self?.set(insufficientAllowance: $0) }
        subscribe(disposeBag, presenter.isLoading) { [weak self] in self?.allowanceView.set(loading: $0) }
        subscribe(disposeBag, presenter.isHidden) { [weak self] in self?.allowanceView.set(hidden: $0) }
    }

    private func set(allowance: String?) {
        allowanceView.bind(title: "swap.allowance".localized, value: allowance)
    }

    private func set(insufficientAllowance: Bool) {
        allowanceView.setValue(color: insufficientAllowance ? .themeLucian : .themeGray)
    }

}
