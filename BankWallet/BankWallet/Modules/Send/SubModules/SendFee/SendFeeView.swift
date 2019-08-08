import UIKit

class SendFeeView: UIView {
    private let feePrefix = "send.fee".localized + " "

    private let delegate: ISendFeeViewDelegate

    private let feeLabel = UILabel()
    private let convertedFeeLabel = UILabel()
    private let errorLabel = UILabel()

    public init(delegate: ISendFeeViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feeHeight)
        }

        backgroundColor = .clear

        addSubview(feeLabel)
        addSubview(errorLabel)
        addSubview(convertedFeeLabel)

        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor
        feeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.feeTitleTopMargin)
        }

        convertedFeeLabel.font = SendTheme.feeFont
        convertedFeeLabel.textColor = SendTheme.feeColor
        convertedFeeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        convertedFeeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.leading.equalTo(feeLabel.snp.trailing).offset(SendTheme.margin)
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }

        feeLabel.text = feePrefix
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }

}

extension SendFeeView: ISendFeeView {

    func set(fee: String?) {
        guard let fee = fee else {
            feeLabel.text = nil
            return
        }
        feeLabel.text = feePrefix + fee
    }

    func set(convertedFee: String?) {
        convertedFeeLabel.text = convertedFee
    }

    func set(error: String?) {
        errorLabel.text = error

        let hide = error != nil

        feeLabel.isHidden = hide
        convertedFeeLabel.isHidden = hide
    }

}
