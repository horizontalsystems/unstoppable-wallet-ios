import UIKit

class MarketTickerCollectionCell: UICollectionViewCell {
    private static let height: CGFloat = 38
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.leading.trailing.equalToSuperview()
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: MarketTickerViewModel.ViewItem) {
        titleLabel.text = viewItem.text
        titleLabel.textColor = Self.color(type: viewItem.type)
        titleLabel.font = Self.font(type: viewItem.type)
    }

}

extension MarketTickerCollectionCell {

    private static func font(type: MarketTickerViewModel.ViewItemType) -> UIFont {
        switch type {
        case .header: return .caption
        case .title: return .captionSB
        case .value: return .micro
        }
    }

    private static func color(type: MarketTickerViewModel.ViewItemType) -> UIColor {
        switch type {
        case .title: return .themeBran
        default: return .themeGray
        }
    }

    public static func size(viewItem: MarketTickerViewModel.ViewItem) -> CGSize {
        let textWidth = viewItem.text.size(containerWidth: .greatestFiniteMagnitude, font: font(type: viewItem.type)).width
        let rightMargin: CGFloat = viewItem.type == .value ? .margin4 : 0

        return CGSize(width: textWidth + rightMargin, height: Self.height)
    }

}
