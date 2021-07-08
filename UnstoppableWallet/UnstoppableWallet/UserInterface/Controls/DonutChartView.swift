import UIKit
import ThemeKit
import SnapKit

class DonutChartView: UIView {

    var baseColor: UIColor = .themeJacob {
        didSet { setNeedsDisplay() }
    }

    var arcWidthPercent: CGFloat = 0.4 {
        didSet { setNeedsDisplay() }
    }

    var percents: [Double] = [] {
        didSet { setNeedsDisplay() }
    }

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(snp.width).dividedBy(2)
        }

        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func color(index: Int, count: Int) -> UIColor {
        let diff = CGFloat(1) / CGFloat(count)
        return baseColor.withAlphaComponent(1 - CGFloat(index) * diff)
    }

    override func draw(_ rect: CGRect) {
        let radius = bounds.width / 2
        let arcWidth = radius * arcWidthPercent

        let center = CGPoint(x: bounds.width / 2, y: bounds.height)

        var currentPercent: Double = 0

        for (index, percent) in percents.enumerated() {
            let nextPercent = currentPercent + percent

            let startAngle: CGFloat = .pi + (.pi / 100 * CGFloat(currentPercent))
            let endAngle: CGFloat = .pi + (.pi / 100 * CGFloat(nextPercent))

            currentPercent = nextPercent

            let path = UIBezierPath(
                    arcCenter: center,
                    radius: radius - arcWidth / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
            )

            path.lineWidth = arcWidth
            color(index: index, count: percents.count).setStroke()
            path.stroke()
        }
    }

}

extension DonutChartView {

    static func height(containerWidth: CGFloat) -> CGFloat {
        containerWidth / 2
    }

}
