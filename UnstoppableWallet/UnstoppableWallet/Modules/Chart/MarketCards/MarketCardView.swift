import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class MarketCardView: UIView {
    class func viewHeight() -> CGFloat { MarketCardTitleView.height + .margin8 + MarketCardValueView.height + 2 * .margin12 }

    let stackView = UIStackView()
    private let titleView = MarketCardTitleView()
    private let valueView = MarketCardValueView()
    private let button = UIButton()

    var onTap: (() -> ())? {
        didSet {
            button.isUserInteractionEnabled = onTap != nil
        }
    }

    required init() {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence
        layer.cornerRadius = .cornerRadius12
        layer.cornerCurve = .continuous
        clipsToBounds = true

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        button.isUserInteractionEnabled = false

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(CGFloat.margin12)
        }

        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = .margin8
        stackView.isUserInteractionEnabled = false

        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(valueView)

        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUI() {
        button.setBackgroundColor(color: .themeLawrencePressed, forState: .highlighted)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUI()
    }

    @objc private func didTapButton() {
        onTap?()
    }

    func set(viewItem: ViewItem) {
        titleView.title = viewItem.title

        valueView.valueColor = viewItem.value == nil ? .themeGray50 : .themeBran
        valueView.value = viewItem.value ?? "n/a".localized

        valueView.diff = viewItem.diff
        if let diffColor = viewItem.diffColor {
            valueView.diffColor = diffColor
        }
    }

}

extension MarketCardView {

    class ViewItem {
        let title: String?
        let value: String?
        let diff: String?
        let diffColor: UIColor?

        init(title: String?, value: String?, diff: String?, diffColor: UIColor?) {
            self.title = title
            self.value = value
            self.diff = diff
            self.diffColor = diffColor
        }

    }

}
