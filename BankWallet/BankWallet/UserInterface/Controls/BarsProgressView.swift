import UIKit
import SnapKit
import RxSwift

class BarsProgressView: UIView {
    private let animationDelay = 200
    private let disposeBag = DisposeBag()
    private var timerDisposable: Disposable?

    private let bars: [UIView]
    private let barWidth: CGFloat
    private let color: UIColor
    private let inactiveColor: UIColor

    var filledCount: Int = 0 {
        didSet {
            if timerDisposable == nil {
                updateBarsVisibility(forCount: bars.count)
            }
        }
    }

    var isAnimating: Bool = false {
        didSet {
            if isAnimating && timerDisposable == nil {
                var visibleCount = 0
                let count = bars.count
                timerDisposable = Observable<Int>
                        .timer(.milliseconds(0), period: .milliseconds(animationDelay), scheduler: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] _ in
                            self?.updateBarsVisibility(forCount: visibleCount)
                            visibleCount += 1
                            visibleCount = visibleCount > count ? 0 : visibleCount
                        })

                timerDisposable?.disposed(by: disposeBag)
            } else if !isAnimating {
                updateBarsVisibility(forCount: bars.count)
                timerDisposable?.dispose()
            }
        }
    }

    init(count: Int, barWidth: CGFloat, color: UIColor, inactiveColor: UIColor) {
        bars = (0..<count).map { _ in
            UIView(frame: .zero)
        }
        self.barWidth = barWidth
        self.color = color
        self.inactiveColor = inactiveColor

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        for i in 0..<bars.count {
            addSubview(bars[i])

            bars[i].snp.makeConstraints { maker in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(barWidth)

                if i > 0 {
                    maker.leading.equalTo(self.bars[i - 1].snp.trailing).offset(barWidth * 0.9)
                }
            }

            bars[i].cornerRadius = barWidth / 2
            bars[i].backgroundColor = inactiveColor
        }

        bars.first?.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
        }
        bars.last?.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
        }
    }

    private func updateBarsVisibility(forCount count: Int) {
        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = index < filledCount ? color : inactiveColor
            bar.backgroundColor = index < count ? bar.backgroundColor : .clear
        }
    }

}
