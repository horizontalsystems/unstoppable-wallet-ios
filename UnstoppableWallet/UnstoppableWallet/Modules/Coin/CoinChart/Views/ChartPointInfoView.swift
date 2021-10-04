import UIKit
import ThemeKit

class ChartPointInfoView: UIView {
    private let leftView = ChartDoubleLineView()
    private let rightView = ChartDoubleLineView(titleFont: .caption, textAlignment: .right)
    private let macdView = MacdPointView()

    init() {
        super.init(frame: .zero)

        addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        leftView.titleColor = .themeOz
        leftView.subtitleColor = .themeGray

        addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(leftView)
        }

        addSubview(macdView)
        macdView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: SelectedPointViewItem) {
        leftView.bind(title: viewItem.value, subtitle: viewItem.date)


        switch viewItem.rightSideMode {
        case .none:
            rightView.isHidden = true
            macdView.isHidden = true
        case .volume(let value):
            let volumeSubtitle = value.map { _ in "chart.selected.volume".localized }
            rightView.bind(title: value, subtitle: volumeSubtitle)

            rightView.titleColor = .themeGray
            rightView.subtitleColor = .themeGray
            rightView.isHidden = value == nil
            macdView.isHidden = true
        case .macd(let macdInfo):
            rightView.isHidden = true
            macdView.isHidden = false
            macdView.bind(histogram: macdInfo.histogram, signal: macdInfo.signal, macd: macdInfo.macd, histogramDown: macdInfo.histogramDown)
        case .dominance(let value, _):
            rightView.titleColor = .themeGray
            rightView.subtitleColor = .themeJacob

            rightView.bind(title: "BTC Dominance", subtitle: value.flatMap { ValueFormatter.instance.format(percentValue: $0, signed: false) })
        }

    }

}
