import UIKit
import ThemeKit
import ComponentKit

class AppearanceAppIconCell: UICollectionViewCell {
    static let height: CGFloat = 89

    private let imageView = UIImageView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview()
            maker.size.equalTo(60)
        }

        imageView.cornerRadius = .cornerRadius12
        imageView.layer.cornerCurve = .continuous

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4)
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin12)
        }

        label.textAlignment = .center
        label.font = .subhead1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: AppearanceViewModel.AppIconViewItem) {
        imageView.image = UIImage(named: viewItem.imageName)
        label.text = viewItem.title
        label.textColor = viewItem.selected ? .themeJacob : .themeLeah
    }

}
