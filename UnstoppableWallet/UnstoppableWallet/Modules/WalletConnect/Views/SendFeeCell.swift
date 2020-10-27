import UIKit
import RxSwift
import RxCocoa

protocol ISendFeeViewModel {
    var feeDriver: Driver<String> { get }
}

class SendFeeCell: UITableViewCell {
    private let feeTitleLabel = UILabel()
    private let feeValueLabel = UILabel()

    private let disposeBag = DisposeBag()

    init(viewModel: ISendFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(feeTitleLabel)
        feeTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        feeTitleLabel.text = "send.fee".localized
        feeTitleLabel.font = .subhead2
        feeTitleLabel.textColor = .themeGray

        contentView.addSubview(feeValueLabel)
        feeValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeTitleLabel.snp.centerY)
            maker.leading.equalTo(feeTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        feeValueLabel.font = .subhead2
        feeValueLabel.textColor = .themeGray
        feeValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        viewModel.feeDriver
                .drive(onNext: { [weak self] status in
                    self?.feeValueLabel.text = status
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
