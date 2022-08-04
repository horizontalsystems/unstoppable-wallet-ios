import UIKit
import ComponentKit

class IndicatorSelectorView: UIView {
    static let cellHeight: CGFloat = 44

    private let bottomSeparatorView = UIView()
    private var indicatorViews = [ChartIndicatorSet : UIButton]()

    public var onTapIndicator: ((ChartIndicatorSet) -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        let emaIndicatorView = SecondaryButton()

        addSubview(emaIndicatorView)
        emaIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(28)
        }

        emaIndicatorView.set(style: .default)
        emaIndicatorView.addTarget(self, action: #selector(tapIndicator), for: .touchUpInside)
        emaIndicatorView.setTitle("EMA", for: .normal)
        emaIndicatorView.tag = Int(ChartIndicatorSet.ema.rawValue)
        indicatorViews[.ema] = emaIndicatorView

        let macdIndicatorView = SecondaryButton()

        addSubview(macdIndicatorView)
        macdIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(emaIndicatorView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(28)
        }

        macdIndicatorView.set(style: .default)
        macdIndicatorView.addTarget(self, action: #selector(tapIndicator), for: .touchUpInside)
        macdIndicatorView.setTitle("MACD", for: .normal)
        macdIndicatorView.tag = Int(ChartIndicatorSet.macd.rawValue)
        indicatorViews[.macd] = macdIndicatorView

        let rsiIndicatorView = SecondaryButton()

        addSubview(rsiIndicatorView)
        rsiIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(macdIndicatorView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(28)
        }

        rsiIndicatorView.set(style: .default)
        rsiIndicatorView.addTarget(self, action: #selector(tapIndicator), for: .touchUpInside)
        rsiIndicatorView.setTitle("RSI", for: .normal)
        rsiIndicatorView.tag = Int(ChartIndicatorSet.rsi.rawValue)
        indicatorViews[.rsi] = rsiIndicatorView

        addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        bottomSeparatorView.backgroundColor = .themeSteel10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapIndicator(sender: UIButton) {
        let indicator = ChartIndicatorSet(rawValue: UInt8(sender.tag))
        onTapIndicator?(indicator)
    }

}

extension IndicatorSelectorView {

    func set(indicator: ChartIndicatorSet, selected: Bool) {
        indicatorViews[indicator]?.isSelected = selected
    }

    func set(indicator: ChartIndicatorSet, disabled: Bool) {
        indicatorViews[indicator]?.isEnabled = !disabled
    }

}
