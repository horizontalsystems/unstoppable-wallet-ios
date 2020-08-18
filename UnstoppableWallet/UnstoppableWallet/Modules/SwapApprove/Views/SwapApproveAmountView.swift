import UIKit

class SwapApproveAmountView: UIView {
    private let amountLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        addSubview(amountLabel)
        addSubview(descriptionLabel)

        amountLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        amountLabel.font = .headline1
        amountLabel.textAlignment = .right
        amountLabel.textColor = .themeJacob

        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray
        descriptionLabel.textAlignment = .right
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(amount: String?, description: String?) {
        amountLabel.text = amount
        descriptionLabel.text = description
    }

}
