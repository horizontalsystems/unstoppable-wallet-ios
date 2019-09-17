import UIKit
import SnapKit

class DoubleLineCellView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = .cryptoBody
        titleLabel.textColor = .appOz
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }

        subtitleLabel.font = .cryptoSubhead2
        subtitleLabel.textColor = .appGray
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String?, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}
