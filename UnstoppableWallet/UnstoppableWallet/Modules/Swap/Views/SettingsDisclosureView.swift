import UIKit
import SnapKit
import ThemeKit

class SettingsDisclosureView: UIView {
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let button = UIButton()

    var onTouchUp: (() -> ())?

    public init() {
        super.init(frame: .zero)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.setBackgroundColor(color: .clear, forState: .normal)
        button.setBackgroundColor(color: .themeLawrencePressed, forState: .highlighted)
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.textColor = .themeGray
        titleLabel.font = .subhead2

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        imageView.image = UIImage(named: "Disclosure Indicator")?.tinted(with: .themeGray)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        onTouchUp?()
    }

    func set(title: String?) {
        titleLabel.text = title
    }

}
