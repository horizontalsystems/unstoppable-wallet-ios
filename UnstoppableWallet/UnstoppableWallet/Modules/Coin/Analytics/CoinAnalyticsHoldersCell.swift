import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import Chart

class CoinAnalyticsHoldersCell: BaseThemeCell {
    static let chartHeight: CGFloat = 40

    var currentStackView: UIStackView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(items: [(Decimal, UIColor?)]) {
        currentStackView?.removeFromSuperview()
        currentStackView = nil

        let stackView = UIStackView()

        stackView.spacing = 1

        var firstView: UIView?
        var firstPercent: Decimal?
        var alpha: CGFloat = 1

        for (percent, color) in items {
            let view = UIView()

            view.cornerRadius = .cornerRadius2

            let resolvedColor: UIColor

            if let color {
                resolvedColor = color
            } else {
                resolvedColor = UIColor.themeJacob.withAlphaComponent(alpha)
                alpha = max(alpha - 0.25, 0.25)
            }

            view.backgroundColor = resolvedColor

            stackView.addArrangedSubview(view)

            if let firstView, let firstPercent {
                let ratio = percent / firstPercent

                view.snp.makeConstraints { make in
                    make.width.equalTo(firstView).multipliedBy((ratio as NSDecimalNumber).doubleValue)
                }
            } else {
                firstView = view
                firstPercent = percent
            }
        }

        wrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview()
            make.height.equalTo(Self.chartHeight)
        }

        currentStackView = stackView
    }

}
