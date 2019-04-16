import UIKit
import SnapKit
import UIExtensions

class FullTransactionProviderLinkCell: UITableViewCell {
    let linkView = FullTransactionLinkView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(linkView)
        contentView.isUserInteractionEnabled = true
        linkView.isUserInteractionEnabled = true
        linkView.linkWrapper.isUserInteractionEnabled = true
        linkView.linkLabel.isUserInteractionEnabled = true
        linkView.snp.makeConstraints { maker in
            maker.centerX.top.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String, onTap: (() -> ())? = nil) {
        linkView.bind(text: text, onTap: onTap)
    }

}
