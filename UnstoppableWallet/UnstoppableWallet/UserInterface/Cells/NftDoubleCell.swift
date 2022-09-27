import UIKit
import SnapKit

class NftDoubleCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16
    private static let topMargin: CGFloat = .margin8
    private static let bottomMarginRegular: CGFloat = .margin4
    private static let bottomMarginLast: CGFloat = .margin32

    private let leftView = NftAssetView()
    private let rightView = NftAssetView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(leftView)
        leftView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview().inset(Self.topMargin)
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.leading.equalTo(leftView.snp.trailing).offset(Self.horizontalMargin)
            maker.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview().inset(Self.topMargin)
            maker.width.equalTo(leftView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func bind(view: NftAssetView, viewItem: ViewItem, onTap: @escaping (ViewItem) -> ()) {
        view.imagePlaceholder = viewItem.name
        view.name = viewItem.name
        view.coinPrice = viewItem.coinPrice
        view.fiatPrice = viewItem.fiatPrice
        view.onSaleHidden = !viewItem.onSale
        view.count = viewItem.count
        view.setImage(url: viewItem.imageUrl)
        view.onTap = { onTap(viewItem) }
    }

}

extension NftDoubleCell {

    func bind(leftViewItem: ViewItem, rightViewItem: ViewItem?, onTap: @escaping (ViewItem) -> ()) {
        bind(view: leftView, viewItem: leftViewItem, onTap: onTap)

        if let rightViewItem = rightViewItem {
            rightView.isHidden = false
            bind(view: rightView, viewItem: rightViewItem, onTap: onTap)
        } else {
            rightView.isHidden = true
        }
    }

}

extension NftDoubleCell {

    static func height(containerWidth: CGFloat, isLast: Bool) -> CGFloat {
        let itemWidth = (containerWidth - horizontalMargin * 3) / 2
        let itemHeight = NftAssetView.height(containerWidth: itemWidth)
        let bottomMargin = isLast ? bottomMarginLast : bottomMarginRegular
        return topMargin + itemHeight + bottomMargin
    }

}

extension NftDoubleCell {

    struct ViewItem {
        let providerCollectionUid: String?
        let nftUid: NftUid
        let imageUrl: String?
        let name: String
        let count: String?
        let onSale: Bool
        let coinPrice: String
        let fiatPrice: String?

        var hash: String {
            "\(count ?? "nil")-\(onSale)-\(coinPrice)-\(fiatPrice ?? "nil")"
        }
    }

}
