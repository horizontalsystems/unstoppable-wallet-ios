import UIKit
import RxSwift
import RxCocoa

class SwapAllowanceCell: AdditionalDataCellNew {
    weak var delegate: IDynamicHeightCellDelegate?

    private let disposeBag = DisposeBag()

    private let viewModel: SwapAllowanceViewModel

    public init(viewModel: SwapAllowanceViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        isVisible = viewModel.isVisible

        subscribe(disposeBag, viewModel.isVisibleSignal) { [weak self] in self?.handle(isVisible: $0) }
        subscribe(disposeBag, viewModel.allowanceDriver) { [weak self] in self?.handle(allowance: $0) }
        subscribe(disposeBag, viewModel.isErrorDriver) { [weak self] in self?.handle(isError: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func handle(isVisible: Bool) {
        self.isVisible = isVisible
        delegate?.onChangeHeight()
    }

    private func handle(allowance: String?) {
        value = allowance
    }

    private func handle(isError: Bool) {
        valueColor = isError ? .themeLucian : .themeGray
    }

}
