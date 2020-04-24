import UIKit

class BottomSheetTitleCell: UITableViewCell {
    private let titleView = BottomSheetTitleView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String?, subtitle: String?, image: UIImage?, onTapClose: @escaping () -> ()) {
        titleView.bind(title: title, subtitle: subtitle, image: image)
        titleView.onTapClose = onTapClose
    }

}
