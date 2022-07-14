import UIKit

class PerformanceSideCollectionViewCell: BasePerformanceCollectionViewCell {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func font(viewItem: CoinOverviewViewModel.PerformanceViewItem) -> UIFont? {
        switch viewItem {
        case .title: return .subhead1
        case .subtitle: return .caption
        case .content: return .caption
        case .value: return nil
        }
    }

    private func color(viewItem: CoinOverviewViewModel.PerformanceViewItem) -> UIColor? {
        switch viewItem {
        case .title: return .themeLeah
        case .subtitle: return .themeBran
        case .content: return .themeGray
        case .value: return nil
        }
    }

    func set(viewItem: CoinOverviewViewModel.PerformanceViewItem, horizontalFirst: Bool, verticalFirst: Bool) {
        super.set(horizontalFirst: horizontalFirst, verticalFirst: verticalFirst)

        label.font = font(viewItem: viewItem)
        label.textColor = color(viewItem: viewItem)
    }

    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

}
