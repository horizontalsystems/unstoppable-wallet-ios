import UIKit
import SnapKit
import UIExtensions

class SelectableValueView: UIView {
    weak var delegate: ISelectableValueViewDelegate?

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    private let wrapperView = RespondView()

    private let dropDownImageView = UIImageView()
    private let lineView = UIView()

    init(title: String) {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(44)
        }

        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(wrapperView)
        addSubview(lineView)

        wrapperView.addSubview(valueLabel)
        wrapperView.addSubview(dropDownImageView)

        titleLabel.text = title
        titleLabel.font = UIFont.appSubhead1
        titleLabel.textColor = .cryptoGray
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(14)
        }

        wrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(44)
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.centerY.equalTo(titleLabel.snp.centerY)
        }

        valueLabel.font = UIFont.appSubhead1
        valueLabel.textColor = .crypto_SteelDark_LightGray
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(10)
            maker.trailing.equalTo(dropDownImageView.snp.leading).offset(-CGFloat.margin2x)
            maker.centerY.equalToSuperview()
            maker.height.equalToSuperview()
        }

        dropDownImageView.image = UIImage(named: "Down")?.tinted(with: .appGray)
        dropDownImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        lineView.backgroundColor = .cryptoSteel20
        lineView.snp.makeConstraints { maker in
            maker.height.equalTo(0.5)
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(13)
        }

        wrapperView.handleTouch = { [weak self] in
            self?.delegate?.onSelectorTap()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func set(value: String) {
        valueLabel.text = value
    }

    func set(enabled: Bool) {
        wrapperView.isUserInteractionEnabled = enabled

        valueLabel.textColor = enabled ? .crypto_SteelDark_LightGray : .appGray50
        dropDownImageView.tintColor = enabled ? .appGray : .appGray50
    }

}

protocol ISelectableValueViewDelegate: class {
    func onSelectorTap()
}
