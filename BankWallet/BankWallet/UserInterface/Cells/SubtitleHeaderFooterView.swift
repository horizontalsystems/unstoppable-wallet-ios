import UIKit
import SnapKit

class SubtitleHeaderFooterView: UITableViewHeaderFooterView {
    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin2x)
        }

        label.font = .appSubhead1
        label.textColor = .cryptoGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text?.uppercased()
    }

}

extension SubtitleHeaderFooterView {
    static let height: CGFloat = 32
}
