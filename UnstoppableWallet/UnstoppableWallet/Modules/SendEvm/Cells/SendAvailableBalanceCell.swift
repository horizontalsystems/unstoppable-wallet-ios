import RxSwift
import SnapKit
import UIKit

class SendAvailableBalanceCell: UITableViewCell {
    let cellHeight: CGFloat = 40

    private let viewModel: ISendAvailableBalanceViewModel
    private let disposeBag = DisposeBag()

    private let wrapperView = UIView()
    private let availableAmountTitleLabel = UILabel()
    private let availableAmountValueLabel = UILabel()
    private let spinner = HUDActivityView.create(with: .small20)

    init(viewModel: ISendAvailableBalanceViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(wrapperView)

        wrapperView.clipsToBounds = true
        wrapperView.cornerRadius = .cornerRadius12
        wrapperView.layer.borderColor = UIColor.themeBlade.cgColor
        wrapperView.layer.borderWidth = .heightOneDp
        wrapperView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        wrapperView.addSubview(availableAmountTitleLabel)
        availableAmountTitleLabel.text = "send.available_balance".localized
        availableAmountTitleLabel.font = .subhead2
        availableAmountTitleLabel.textColor = .themeGray
        availableAmountTitleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
        }

        wrapperView.addSubview(availableAmountValueLabel)
        availableAmountValueLabel.font = .subhead1

        availableAmountValueLabel.textColor = .themeLeah
        availableAmountValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        wrapperView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        subscribe(disposeBag, viewModel.viewStateDriver) { [weak self] in self?.sync(viewState: $0) }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(viewState: SendAvailableBalanceViewModel.ViewState) {
        if case .loading = viewState {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }

        if case let .loaded(value) = viewState {
            availableAmountValueLabel.text = value
            availableAmountValueLabel.isHidden = false
        } else {
            availableAmountValueLabel.isHidden = true
        }
    }
}
