import UIKit
import SnapKit

class DoubleLineImageCellView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(imageView)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(AppTheme.margin4x)
        }

        titleLabel.font = .cryptoBody
        titleLabel.textColor = .appOz
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(AppTheme.margin4x)
            maker.trailing.equalToSuperview().offset(-AppTheme.margin4x)
            maker.top.equalToSuperview().offset(AppTheme.margin2x)
        }

        subtitleLabel.font = .cryptoSubhead2
        subtitleLabel.textColor = .cryptoGray
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(AppTheme.margin4x)
            maker.trailing.equalToSuperview().offset(-AppTheme.margin4x)
            maker.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, title: String?, subtitle: String?) {
        imageView.image = image
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}
