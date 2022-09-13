import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class MarketCardCell: UITableViewCell {
    private let stackView = UIStackView()
    private(set) var marketCardViews = [UIView]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.axis = .horizontal
        stackView.spacing = .margin8
        stackView.distribution = .fillEqually
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func append(viewItem: MarketCardView.ViewItem, onTap: (() -> ())? = nil) {
        let marketCardView = MarketCardView()
        marketCardView.onTap = onTap

        append(view: marketCardView)
        marketCardView.set(viewItem: viewItem)
    }

}

extension MarketCardCell {

    func append(view: UIView?) {
        guard let view = view else {
            return
        }

        marketCardViews.append(view)
        stackView.addArrangedSubview(view)
    }

    func remove(at index: Int) {
        guard index < marketCardViews.count else {
            return
        }

        stackView.removeArrangedSubview(marketCardViews[index])
        marketCardViews.remove(at: index)
    }

    func set(hidden: Bool, at index: Int) {
        guard index < marketCardViews.count else {
            return
        }

        marketCardViews[index].isHidden = hidden
    }

    func clear() {
        marketCardViews.forEach { view in
            stackView.removeArrangedSubview(view)
        }

        marketCardViews.removeAll()
    }

}
