import UIKit
import HUD

class AdditionalDataWithErrorView: UIView {
    private let additionalDataView = AdditionalDataView()
    private let errorLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(AdditionalDataView.height)
        }

        backgroundColor = .clear

        addSubview(additionalDataView)
        addSubview(errorLabel)

        additionalDataView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }

        errorLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.greaterThanOrEqualToSuperview().inset(CGFloat.margin3x)
        }

        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        errorLabel.font = .caption
        errorLabel.textColor = .themeLucian
        errorLabel.numberOfLines = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String?, value: String?) {
        additionalDataView.isHidden = false
        additionalDataView.bind(title: title, value: value)

        errorLabel.text = nil
    }

    func bind(error: String?) {
        additionalDataView.isHidden = error != nil

        errorLabel.text = error
    }


    func setValue(color: UIColor) {
        additionalDataView.setValue(color: color)
    }

}
