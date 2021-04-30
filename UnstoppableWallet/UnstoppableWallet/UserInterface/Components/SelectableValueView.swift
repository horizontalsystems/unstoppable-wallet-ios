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

        lineView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        lineView.backgroundColor = .themeSteel20

        titleLabel.text = title
        titleLabel.font = UIFont.subhead2
        titleLabel.textColor = .themeGray
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalTo(lineView).offset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(13)
        }

        wrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(44)
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.centerY.equalTo(titleLabel.snp.centerY)
        }

        valueLabel.font = UIFont.subhead1
        valueLabel.textColor = .themeLeah
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(10)
            maker.trailing.equalTo(dropDownImageView.snp.leading).offset(-CGFloat.margin2x)
            maker.centerY.equalToSuperview()
            maker.height.equalToSuperview()
        }

        dropDownImageView.image = UIImage(named: "arrow_small_down_20")
        dropDownImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
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

        valueLabel.textColor = enabled ? .themeLeah : .themeGray50
        dropDownImageView.tintColor = enabled ? .themeGray : .themeGray50
    }

}

protocol ISelectableValueViewDelegate: AnyObject {
    func onSelectorTap()
}
