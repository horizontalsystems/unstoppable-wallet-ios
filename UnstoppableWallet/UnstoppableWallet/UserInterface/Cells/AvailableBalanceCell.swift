import UIKit
import RxSwift
import RxCocoa

protocol IAvailableBalanceCellViewModel {
    var balanceDriver: Driver<String> { get }
}

class AvailableBalanceCell: UITableViewCell {
    private let balanceTitleLabel = UILabel()
    private let balanceValueLabel = UILabel()

    private let disposeBag = DisposeBag()

    init(viewModel: IAvailableBalanceCellViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(balanceTitleLabel)
        balanceTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        balanceTitleLabel.text = "send.available_balance".localized
        balanceTitleLabel.font = .subhead2
        balanceTitleLabel.textColor = .themeGray

        contentView.addSubview(balanceValueLabel)
        balanceValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(balanceTitleLabel.snp.centerY)
            maker.leading.equalTo(balanceTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        balanceValueLabel.font = .subhead2
        balanceValueLabel.textColor = .themeGray
        balanceValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        viewModel.balanceDriver
                .drive(onNext: { [weak self] balance in
                    self?.balanceValueLabel.text = balance
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension AvailableBalanceCell {

    static var height: CGFloat {
        29
    }

}
