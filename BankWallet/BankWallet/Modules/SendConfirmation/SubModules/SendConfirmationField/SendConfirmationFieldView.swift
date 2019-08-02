import UIKit
import SnapKit

class SendConfirmationFieldView: UIView {

    private let titleLabel = UILabel()
    private let textLabel = UILabel()

    public init(title: String, text: String) {
        super.init(frame: .zero)

        backgroundColor = .clear

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.confirmationFieldHeight)
        }

        addSubview(titleLabel)
        addSubview(textLabel)

        titleLabel.textColor = .cryptoGray
        titleLabel.font = .cryptoCaption1
        titleLabel.text = title

        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.bottom.equalToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        textLabel.textColor = .cryptoGray
        textLabel.font = .cryptoCaption1
        textLabel.text = text

        textLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.bottom.equalToSuperview()
        }

        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}
