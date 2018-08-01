import UIKit
import SnapKit
import RxSwift
import RxCocoa

class AmountInputField: UIView {
    let disposeBag = DisposeBag()

    var amountInputField = UITextField()
    var currencyButton = RespondButton()
    var dropDownImageView = UIImageView(image: UIImage(named: "Currency Drop Down"))
    var exchangeValueLabel = UILabel()

    var onAmountChange: ((String?) -> ())?

    public init() {
        super.init(frame: .zero)
        borderWidth = SendTheme.inputBorderWidth
        borderColor = SendTheme.inputBorderColor
        cornerRadius = SendTheme.inputCornerRadius

        addSubview(amountInputField)
        amountInputField.keyboardType = .decimalPad
        amountInputField.tintColor = SendTheme.inputTintColor
        amountInputField.textColor = SendTheme.inputTextColor
        amountInputField.font = SendTheme.inputFont
        amountInputField.placeholder = "amount".localized
        amountInputField.rx.controlEvent(.editingChanged).subscribe(onNext: { [weak self] _ in
            self?.onAmountChange?(self?.amountInputField.text)
        }).disposed(by: disposeBag)

        addSubview(currencyButton)
        currencyButton.borderWidth = 1 / UIScreen.main.scale
        currencyButton.borderColor = SendTheme.buttonBorderColor
        currencyButton.cornerRadius = SendTheme.buttonCornerRadius
        currencyButton.backgrounds = ButtonTheme.grayBackgroundDictionary
        currencyButton.textColors = SendTheme.buttonTextDictionary
        currencyButton.titleLabel.text = "USD".localized
        currencyButton.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        currencyButton.addSubview(dropDownImageView)

        let separatorView = UIView()
        separatorView.backgroundColor = SendTheme.separatorBackground
        addSubview(separatorView)

        addSubview(exchangeValueLabel)
        exchangeValueLabel.textColor = SendTheme.exchangeValueTextColor
        exchangeValueLabel.font = SendTheme.exchangeValueFont
        exchangeValueLabel.text = "0.000 BTC"

        amountInputField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalToSuperview()
            maker.trailing.equalTo(currencyButton.snp.leading).offset(-SendTheme.smallMargin)
            maker.bottom.equalTo(separatorView.snp.top)
        }
        currencyButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.buttonSideMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.buttonSideMargin)
            maker.bottom.equalTo(separatorView.snp.top).offset(-SendTheme.buttonSideMargin)
        }
        currencyButton.titleLabel.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.buttonTitleMargin)
            maker.top.bottom.equalToSuperview()
            maker.trailing.equalTo(dropDownImageView.snp.leading).offset(-SendTheme.currencyDropImageLeftMargin)
        }
        dropDownImageView.snp.makeConstraints { maker in
            maker.size.equalTo(SendTheme.currencyDropImageSize)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.currencyDropImageRightMargin)
        }
        separatorView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.amountInputHeight)
            maker.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 0, left: SendTheme.buttonSideMargin, bottom: 0, right: SendTheme.buttonSideMargin))
            maker.height.equalTo(SendTheme.separatorHeight)
        }
        exchangeValueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.sideMargin)
            maker.top.equalTo(separatorView.snp.bottom).offset(SendTheme.smallestMargin)
            maker.bottom.equalToSuperview().offset(-SendTheme.buttonSideMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
