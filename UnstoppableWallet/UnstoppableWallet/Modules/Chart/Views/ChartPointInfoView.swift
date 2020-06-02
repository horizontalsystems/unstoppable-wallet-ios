import UIKit
import ThemeKit

class ChartPointInfoView: UIView {
    private let leftView = ChartDoubleLineView()
    private let rightView = ChartDoubleLineView(titleColor: .themeGray, titleFont: .caption, textAlignment: .right)

    init() {
        super.init(frame: .zero)

        addSubview(leftView)
        addSubview(rightView)

        leftView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }
        rightView.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(leftView)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(date: String?, price: String?, volume: String?) {
        leftView.bind(title: price, subtitle: date)

        let volumeSubtitle = volume.map { _ in "chart.selected.volume".localized }
        rightView.bind(title: volume, subtitle: volumeSubtitle)
    }

}
