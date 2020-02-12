import UIKit

class ChartPointInfoView: UIView {
    private let dateView = DoubleLineView()
    private let priceView = DoubleLineView()
    private let volumeView = DoubleLineView()

    init() {
        super.init(frame: .zero)

        addSubview(dateView)
        addSubview(priceView)
        addSubview(volumeView)

        dateView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }
        priceView.snp.makeConstraints { maker in
            maker.leading.equalTo(dateView.snp.trailing).offset(CGFloat.margin1x)
            maker.top.bottom.equalTo(dateView)
            maker.width.equalTo(dateView)
        }
        volumeView.snp.makeConstraints { maker in
            maker.leading.equalTo(priceView.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalToSuperview()
            maker.top.bottom.equalTo(volumeView)
            maker.width.equalTo(priceView)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(date: String?, time: String?, price: String?, volume: String?) {
        dateView.bind(title: date, subtitle: time)

        let priceSubtitle = price.map { _ in "chart.selected.price".localized }
        priceView.bind(title: price, subtitle: priceSubtitle)

        let volumeSubtitle = volume.map { _ in "chart.selected.volume".localized }
        volumeView.bind(title: volume, subtitle: volumeSubtitle)
    }

}
