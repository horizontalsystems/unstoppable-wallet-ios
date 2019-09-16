import UIKit
import SnapKit

class CheckmarkCellView: UIView {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.image = UIImage(named: "Confirmations Icon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = SettingsTheme.checkmarkTintColor
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SettingsTheme.cellBigMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(visible: Bool) {
        imageView.isHidden = !visible
    }

}
