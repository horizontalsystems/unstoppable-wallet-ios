import UIKit
import UIExtensions
import ThemeKit
import SnapKit

class MarketFieldModeView: UIView {
    private let stackView = UIStackView()
    private var allButtons = [UIButton]()

    var onSelect: ((MarketModule.MarketField) -> ())?
    private var currentSelected: MarketModule.MarketField

    init() {
        currentSelected = MarketModule.MarketField.allCases[0]

        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.spacing = .margin8
        stackView.alignment = .fill

        MarketModule.MarketField.allCases.forEach { field in
            let button = ThemeButton().apply(style: .tertiary)
            allButtons.append(button)

            stackView.addArrangedSubview(button)

            button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
            button.setTitle(field.title, for: .normal)
            button.tag = field.rawValue
        }

        allButtons.first?.isSelected = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap(_ button: UIButton) {
        guard let field = MarketModule.MarketField(rawValue: button.tag) else {
            return
        }

        if currentSelected != field {
            setSelected(field: field)
            onSelect?(field)
        }
    }

}

extension MarketFieldModeView {

    public func setSelected(field: MarketModule.MarketField) {
        currentSelected = field
        allButtons.forEach { button in
            button.isSelected = button.tag == field.rawValue
        }
    }

}
