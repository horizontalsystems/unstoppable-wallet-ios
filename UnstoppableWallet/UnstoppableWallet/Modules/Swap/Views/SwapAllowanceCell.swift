import UIKit
import RxSwift
import RxCocoa

class SwapAllowanceCell: UITableViewCell {
    private var disposeBag = DisposeBag()

    private let viewModel: SwapAllowanceViewModel
    private let allowanceView = AdditionalDataView()

    public init(viewModel: SwapAllowanceViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(allowanceView)
        allowanceView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func viewDidLoad() {
        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.allowance) { [weak self] in self?.set(allowance: $0) }
        subscribe(disposeBag, viewModel.insufficientAllowance) { [weak self] in self?.set(insufficientAllowance: $0) }
        subscribe(disposeBag, viewModel.isLoading) { [weak self] in self?.set(loading: $0) }
        subscribe(disposeBag, viewModel.isHidden) { [weak self] in self?.set(hidden: $0) }
    }

    private func set(allowance: String?) {
        allowanceView.bind(title: "swap.allowance".localized, value: allowance)
    }

    private func set(loading: Bool) {
        if loading {
            allowanceView.bind(title: "swap.allowance".localized, value: "action.loading".localized)
            allowanceView.setValue(color: .themeGray)
        }
    }

    private func set(insufficientAllowance: Bool) {
        allowanceView.setValue(color: insufficientAllowance ? .themeLucian : .themeGray)
    }

    private func set(hidden: Bool) {
        allowanceView.set(hidden: hidden)
    }

}
