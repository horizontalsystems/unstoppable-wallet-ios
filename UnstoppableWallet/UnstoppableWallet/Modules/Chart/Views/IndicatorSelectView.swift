import UIKit
import SnapKit

class IndicatorSelectView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let button = UIButton()

    var onTap: (() -> ())?

    init(title: String) {
        super.init(frame: .zero)

        let separator = UIView()
        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separator.backgroundColor = .themeSteel20

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x + CGFloat.margin4x + CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.font = .subhead2
        titleLabel.text = title

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        valueLabel.font = .subhead1

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageView?.translatesAutoresizingMaskIntoConstraints = false
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(onSelect), for: .touchUpInside)
        button.setImage(UIImage(named: "eye_20")?.tinted(with: .themeJacob), for: .selected)
        button.setImage(UIImage(named: "eye_20")?.tinted(with: .themeGray), for: .normal)
        button.setImage(UIImage(named: "eye_20")?.tinted(with: .themeGray50), for: .disabled)
        button.imageEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 0)
        button.contentHorizontalAlignment = .left
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onSelect() {
        onTap?()
    }

    func bind(selected: Bool, trend: MovementTrend?) {
        button.isSelected = selected

        guard let trend = trend else {
            valueLabel.isHidden = true
            button.isSelected = false
            titleLabel.textColor = .themeGray50
            button.isUserInteractionEnabled = false
            return
        }

        valueLabel.isHidden = false
        button.isUserInteractionEnabled = true
        titleLabel.textColor = .themeGray

        switch trend {
        case .neutral:
            valueLabel.textColor = .themeGray
            valueLabel.text = "chart.trend_neutral".localized
        case .down:
            valueLabel.textColor = .themeLucian
            valueLabel.text = "chart.trend_down".localized
        case .up:
            valueLabel.textColor = .themeRemus
            valueLabel.text = "chart.trend_up".localized
        }
    }

}
