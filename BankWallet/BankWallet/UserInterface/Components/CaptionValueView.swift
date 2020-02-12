import UIKit
import SnapKit

class CaptionValueView: UIView {
    private let captionLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        captionLabel.font = .subhead2
        captionLabel.textColor = .themeGray

        addSubview(captionLabel)
        captionLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(captionLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.top.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(caption: String?) {
        captionLabel.text = caption
    }

    func set(value: String?, accent: Bool = true, font: UIFont = .subhead2) {
        valueLabel.text = value
        valueLabel.font = font
        valueLabel.textColor = accent ? .themeLeah : .themeGray50
    }

}
