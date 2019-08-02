import UIKit
import SnapKit

class SendConfirmationPrimaryView: UIView {
    private let delegate: ISendConfirmationPrimaryViewDelegate

    private let holderView = UIView()

    private let primaryAmountLabel = UILabel()
    private let secondaryAmountLabel = UILabel()
    private let lineView = UIView()
    private let toLabel = UILabel()
    private let hashView = HashView()
    private var onHashTap: (() -> ())?


    public init(delegate: ISendConfirmationPrimaryViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.confirmationPrimaryHeight)
        }

        addSubview(holderView)

        holderView.addSubview(primaryAmountLabel)
        holderView.addSubview(secondaryAmountLabel)
        holderView.addSubview(lineView)
        holderView.addSubview(hashView)
        holderView.addSubview(toLabel)

        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(SendTheme.margin)
            maker.top.bottom.equalToSuperview()
        }

        holderView.layer.cornerRadius = SendTheme.holderCornerRadius

        holderView.layer.borderWidth = SendTheme.holderBorderWidth
        holderView.layer.borderColor = SendTheme.holderBorderColor.cgColor
        holderView.backgroundColor = SendTheme.holderBackground

        primaryAmountLabel.font = SendTheme.confirmationPrimaryAmountFont
        primaryAmountLabel.textColor = SendTheme.confirmationPrimaryAmountColor
        primaryAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.confirmationPrimaryMargin)
        }

        secondaryAmountLabel.font = SendTheme.confirmationSecondaryFont
        secondaryAmountLabel.textColor = SendTheme.confirmationSecondaryColor
        secondaryAmountLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.primaryAmountLabel.snp.bottom).offset(SendTheme.confirmationSecondaryTopMargin)
        }

        lineView.backgroundColor = SendTheme.amountLineColor
        lineView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(SendTheme.confirmationPrimaryLineTopMargin)
            maker.height.equalTo(SendTheme.amountLineHeight)
        }

        toLabel.font = SendTheme.confirmationToLabelFont
        toLabel.textColor = SendTheme.confirmationToLabelColor
        toLabel.text = "send.confirmation.to"
        toLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(lineView.snp.bottom).offset(SendTheme.confirmationToLabelTopMargin)
        }
        toLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        toLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        hashView.snp.makeConstraints { maker in
            maker.leading.equalTo(toLabel.snp.trailing).offset(SendTheme.smallMargin)
            maker.top.equalTo(lineView.snp.bottom).offset(SendTheme.confirmationReceiverTopMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }
        hashView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        hashView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        onHashTap = { [weak self] in
            self?.delegate.onCopyReceiverClick()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }

}

extension SendConfirmationPrimaryView: ISendConfirmationPrimaryView {

    func set(primaryAmount: String?) {
        primaryAmountLabel.text = primaryAmount
    }

    func set(secondaryAmount: String?) {
        secondaryAmountLabel.text = secondaryAmount
    }

    func set(receiver: String) {
        hashView.bind(value: receiver, showExtra: .icon, onTap: onHashTap)
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
