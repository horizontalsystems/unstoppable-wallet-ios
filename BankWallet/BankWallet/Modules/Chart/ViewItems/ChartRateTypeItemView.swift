import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ChartRateTypeItemView: BaseActionItemView {
    private let buttonHeight: CGFloat = 24
    private let buttonDefaultWidth: CGFloat = 60
    private let buttonTopMargin: CGFloat = 10

    private let chartTypeSelectView = ChartTypeSelectView()

    private let selectedPointInfoView = ChartPointInfoView()

    override var item: ChartRateTypeItem? {
        _item as? ChartRateTypeItem
    }

    override func initView() {
        super.initView()

        addSubview(selectedPointInfoView)
        selectedPointInfoView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(9)
            maker.bottom.equalToSuperview().inset(6)
            maker.trailing.leading.equalToSuperview().inset(CGFloat.margin4x)
        }

        addSubview(chartTypeSelectView)
        chartTypeSelectView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(10)
            maker.trailing.leading.equalToSuperview().inset(CGFloat.margin4x)
        }
        chartTypeSelectView.onSelectIndex = { [weak self] index in
            self?.item?.didSelect?(index)
        }
        item?.setTitles = {[weak self] titles in
            self?.set(titles: titles)
        }
        item?.setSelected = { [weak self] index in
            self?.setSelected(index: index)
        }
        item?.showPoint = { [weak self] date, time, price, volume in
            self?.showPoint(date: date, time: time, price: price, volume: volume)
        }
    }

    private func showPoint(date: String?, time: String?, price: String?, volume: String?) {
        selectedPointInfoView.bind(date: date, time: time, price: price, volume: volume)
        showButtons(date == nil || price == nil)
    }

    private func showButtons(_ show: Bool) {
        selectedPointInfoView.isHidden = show
        chartTypeSelectView.isHidden = !show
    }

    private func setSelected(index: Int) {
        chartTypeSelectView.select(index: index)
    }

    private func set(titles: [String]) {
        chartTypeSelectView.reload(titles: titles)
    }

}
