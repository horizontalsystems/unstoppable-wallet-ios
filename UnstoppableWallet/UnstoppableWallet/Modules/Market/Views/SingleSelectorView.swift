import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit

class SingleSelectorView: UIView {
    private let stackView = UIStackView()
    private var allButtons = [UIButton]()

    var onSelect: ((Int) -> ())?
    private var currentSelected: Int = 0

    init(titles: [String] = []) {
        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.spacing = .margin8
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally

        set(items: titles)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap(_ button: UIButton) {
        let index = button.tag

        if currentSelected != index {
            setSelected(index: index)
            onSelect?(index)
        }
    }

}

extension SingleSelectorView {

    func set(items: [String]) {
        allButtons = []

        items.enumerated().forEach { index, title in
            let button = ThemeButton().apply(style: .tertiary)
            allButtons.append(button)

            stackView.addArrangedSubview(button)

            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
            button.setTitle(title, for: .normal)
            button.tag = index
        }

        allButtons.first?.isSelected = true
    }

    func setSelected(index: Int) {
        currentSelected = index
        allButtons.forEach { button in
            button.isSelected = button.tag == index
        }
    }

}
