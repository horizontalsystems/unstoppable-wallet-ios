import UIKit
import SnapKit

class CardCell: UITableViewCell {
    static let cardMargins = CGFloat.margin4x * 2

    private let roundedBackground = UIView()
    let clippingView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        roundedBackground.backgroundColor = .appLawrence
        roundedBackground.layer.cornerRadius = .cornerRadius16
        roundedBackground.layer.shadowColor = UIColor.appAndy.cgColor
        roundedBackground.layer.shadowRadius = .cornerRadius8
        roundedBackground.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().offset(-CGFloat.margin2x)
        }

        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = .cornerRadius16
        roundedBackground.addSubview(clippingView)
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }

}
