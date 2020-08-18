import UIKit
import RxSwift

class SwapInputModuleView: UIView {
    private let disposeBag = DisposeBag()
    private let viewModel: ISwapInputViewModel

    private let swapHeaderView = SwapHeaderView()
    private let swapInputView = SwapInputView()

    init(viewModel: ISwapInputViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        swapHeaderView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        swapHeaderView.set(title: viewModel.description.localized)
        swapHeaderView.setBadge(text: "swap.estimated".localized)
        swapHeaderView.setBadge(hidden: true)

        swapInputView.snp.makeConstraints { maker in
            maker.top.equalTo(swapHeaderView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        swapInputView.set(maxButtonVisible: false)
        swapInputView.delegate = self

        subscribeViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscribeViewModel() {
        subscribe(disposeBag, viewModel.isEstimated) { [weak self] in self?.swapHeaderView.setBadge(hidden: !$0) }
        subscribe(disposeBag, viewModel.isLoading) { [weak self] in self?.swapHeaderView.set(loading: $0) }

        subscribe(disposeBag, viewModel.amount) { [weak self] in self?.swapInputView.set(text: $0) }
        subscribe(disposeBag, viewModel.tokenCode) { [weak self] in self?.swapInputView.set(tokenCode: $0) }
    }

}

extension SwapInputModuleView: ISwapInputViewDelegate {

    func isValid(_ inputView: SwapInputView, text: String) -> Bool {
        if viewModel.isValid(amount: text) {
            return true
        } else {
            inputView.shakeView()
            return false
        }
    }

    func willChangeAmount(_ inputView: SwapInputView, text: String?) {
        viewModel.onChange(amount: text)
    }

    func onMaxClicked(_ inputView: SwapInputView) {     // not implemented yet
    }

    func onTokenSelectClicked(_ inputView: SwapInputView) {
        // todo: get coins and show token select.
    }

}
