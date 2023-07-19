import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class IndicatorAdviceView: UIView {
    static private let blockHeight: CGFloat = 6

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let stackView = UIStackView()

    private var blocks = [UIView]()

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    init() {
        super.init(frame: .zero)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        titleLabel.font = .subhead1
        titleLabel.textColor = .gray

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing)
        }

        valueLabel.textAlignment = .right
        valueLabel.font = .subhead1
        valueLabel.textColor = .gray
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.blockHeight)
            make.bottom.equalToSuperview()
        }

        stackView.spacing = 1
        stackView.distribution = .fillEqually

        for _ in 0..<CoinIndicatorViewItemFactory.Advice.allCases.count {
            let view = UIView()
            view.clipsToBounds = true
            view.cornerRadius = .cornerRadius2
            view.backgroundColor = .themeSteel20

            blocks.append(view)
            stackView.addArrangedSubview(view)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateBlocks(advice: CoinIndicatorViewItemFactory.Advice?) {
        guard let advice else {
            blocks.forEach { $0.backgroundColor = .themeSteel20 }
            return
        }

        for i in 0..<CoinIndicatorViewItemFactory.Advice.allCases.count {
            let blockColor = CoinIndicatorViewItemFactory.Advice(rawValue: i)?.color ?? UIColor.themeSteel20
            blocks.at(index: i)?.backgroundColor = advice.rawValue >= i ? blockColor : blockColor.withAlphaComponent(0.2)
        }
    }

}

extension IndicatorAdviceView {

    func set(advice: CoinIndicatorViewItemFactory.Advice?) {
        valueLabel.text = advice?.title
        valueLabel.textColor = advice?.color ?? .themeGray
        updateBlocks(advice: advice)
    }

    func setEmpty(title: String?, value: String?) {
        titleLabel.text = title
        valueLabel.text = value
        valueLabel.textColor = .themeGray
        updateBlocks(advice: nil)
    }

}
