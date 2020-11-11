import UIKit
import RxSwift
import RxCocoa

class SwapAllowanceCell: UITableViewCell {
    static let height: CGFloat = AdditionalDataView.height

    weak var delegate: IDynamicHeightCellDelegate?

    private let disposeBag = DisposeBag()

    private let viewModel: SwapAllowanceViewModelNew
    private let additionalDataView = AdditionalDataView()

    public init(viewModel: SwapAllowanceViewModelNew) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(additionalDataView)
        additionalDataView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        subscribe(disposeBag, viewModel.isVisibleSignal) { [weak self] in self?.handle(isVisible: $0) }
        subscribe(disposeBag, viewModel.allowanceDriver) { [weak self] in self?.handle(allowance: $0) }
        subscribe(disposeBag, viewModel.isErrorDriver) { [weak self] in self?.handle(isError: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func handle(isVisible: Bool) {
        delegate?.onChangeHeight()
    }

    private func handle(allowance: String?) {
        additionalDataView.bind(title: "swap.allowance".localized, value: allowance)
    }

    private func handle(isError: Bool) {
        additionalDataView.setValue(color: isError ? .themeLucian : .themeGray)
    }

}

extension SwapAllowanceCell {

    var isVisible: Bool {
        viewModel.isVisible
    }

}