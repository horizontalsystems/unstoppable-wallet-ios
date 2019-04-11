import UIKit
import SnapKit

class BarsProgressView: UIView {

    private let bars: [UIView]
    private let color: UIColor
    private let inactiveColor: UIColor

    var filledCount: Int = 0 {
        didSet {
            for (index, bar) in bars.enumerated() {
                bar.backgroundColor = index < filledCount ? color : inactiveColor
            }
        }
    }

    init(count: Int, barWidth: CGFloat, color: UIColor, inactiveColor: UIColor) {
        bars = (0..<count).map { _ in
            UIView(frame: .zero)
        }
        self.color = color
        self.inactiveColor = inactiveColor

        super.init(frame: .zero)

        for i in 0..<bars.count {
            addSubview(bars[i])

            bars[i].cornerRadius = barWidth / 2
            bars[i].backgroundColor = inactiveColor

            bars[i].snp.makeConstraints { maker in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(barWidth)

                if i > 0 {
                    maker.leading.equalTo(self.bars[i - 1].snp.trailing).offset(barWidth * 0.9)
                }
            }
        }

        bars.first?.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
        }
        bars.last?.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
