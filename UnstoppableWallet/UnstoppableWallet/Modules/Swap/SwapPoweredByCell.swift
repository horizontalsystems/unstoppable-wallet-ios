import UIKit
import SnapKit
import ThemeKit

class SwapPoweredByCell: UITableViewCell {
    private let label = UILabel()

    var isVisible = true

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .caption
        label.textColor = .themeGray
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func dexName(dex: SwapModule.Dex) -> String {
        switch dex{
        case .uniswap: return "Uniswap"
        case .pancake: return "PancakeSwap"
        }
    }

    func set(dex: SwapModule.Dex) {
        label.text = "Powered by \(dexName(dex: dex))"
    }

    var cellHeight: CGFloat {
        isVisible ? 20 : 0
    }

}
