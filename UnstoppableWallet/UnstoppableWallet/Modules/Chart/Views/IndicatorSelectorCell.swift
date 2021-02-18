import UIKit
import ThemeKit

class IndicatorSelectorCell: UITableViewCell {
    private var indicatorViews = [ChartIndicatorSet : UIButton]()

    public var onTapIndicator: ((ChartIndicatorSet) -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let emaIndicatorView = ThemeButton().apply(style: .tertiary)
        contentView.addSubview(emaIndicatorView)
        emaIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(24)
        }

        emaIndicatorView.addTarget(self, action: #selector(tapIndicator), for: .touchUpInside)
        emaIndicatorView.setTitle("EMA", for: .normal)
        emaIndicatorView.tag = Int(ChartIndicatorSet.ema.rawValue)
        indicatorViews[.ema] = emaIndicatorView

        let macdIndicatorView = ThemeButton().apply(style: .tertiary)
        contentView.addSubview(macdIndicatorView)
        macdIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(emaIndicatorView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(24)
        }

        macdIndicatorView.addTarget(self, action: #selector(tapIndicator), for: .touchUpInside)
        macdIndicatorView.setTitle("MACD", for: .normal)
        macdIndicatorView.tag = Int(ChartIndicatorSet.macd.rawValue)
        indicatorViews[.macd] = macdIndicatorView

        let rsiIndicatorView = ThemeButton().apply(style: .tertiary)
        contentView.addSubview(rsiIndicatorView)
        rsiIndicatorView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(macdIndicatorView.snp.trailing).offset(CGFloat.margin8)
            maker.height.equalTo(24)
        }

        rsiIndicatorView.addTarget(self, action: #selector(tapIndicator), for: .touchUpInside)
        rsiIndicatorView.setTitle("RSI", for: .normal)
        rsiIndicatorView.tag = Int(ChartIndicatorSet.rsi.rawValue)
        indicatorViews[.rsi] = rsiIndicatorView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapIndicator(sender: UIButton) {
        let indicator = ChartIndicatorSet(rawValue: UInt8(sender.tag))
        onTapIndicator?(indicator)
    }

    public func bind(indicator: ChartIndicatorSet, selected: Bool) {
        indicatorViews[indicator]?.isSelected = selected
    }

}
