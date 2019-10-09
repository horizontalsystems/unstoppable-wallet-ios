import UIKit
import SnapKit

class CaptionValueView: UIView {
    private let captionLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        captionLabel.font = .appSubhead2
        captionLabel.textColor = .appGray

        addSubview(captionLabel)
        captionLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        valueLabel.font = .appSubhead2
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

    func set(value: String?, accent: Bool = false) {
        valueLabel.text = value
        valueLabel.textColor = accent ? .appLeah : .appGray
    }

}
