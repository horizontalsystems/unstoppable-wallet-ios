import UIKit
import SnapKit
import RxSwift

class BarsProgressView: UIView {
    static let progressStepsCount = 3

    private let animationDelay = 400
    private let disposeBag = DisposeBag()
    private var animateDisposable: Disposable?

    private var bars: [UIView] = []
    private let barWidth: CGFloat
    private let color: UIColor
    private let inactiveColor: UIColor
    private var filledColor: UIColor

    private var progress: Double = 0
    private var filledCount: Int = 0 {
        didSet {
            if animateDisposable == nil {
                updateFillColor(fullFillBefore: filledCount)
            }
        }
    }

    init(barWidth: CGFloat, color: UIColor, inactiveColor: UIColor) {
        self.barWidth = barWidth
        self.color = color
        self.inactiveColor = inactiveColor
        filledColor = color

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(progress: Double) {
        filledCount = Int(Double(bars.count) * progress)
    }

    func set(filledColor: UIColor) {
        self.filledColor = filledColor
    }

    func set(barsCount count: Int) {
        bars.forEach { $0.removeFromSuperview() }

        bars = (0..<count).map { _ in
            UIView(frame: .zero)
        }

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

        set(progress: progress)
    }

    func startAnimating() {
        guard animateDisposable == nil else {
            return
        }

        var dx = 0
        let count = bars.count
        animateDisposable = Observable<Int>
                .timer(.milliseconds(0), period: .milliseconds(animationDelay), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    let startIndex = self?.filledCount ?? 0
                    self?.updateFillColor(fullFillBefore: startIndex + dx)
                    dx += 1
                    dx = startIndex + dx > count ? 0 : dx
                })

        animateDisposable?.disposed(by: disposeBag)
    }

    func stopAnimating() {
        updateFillColor(fullFillBefore: filledCount)
        animateDisposable?.dispose()
        animateDisposable = nil
    }

    private func updateFillColor(fullFillBefore count: Int) {
        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = index < filledCount ? filledColor : (index < count ? color : inactiveColor)
        }
    }

}
