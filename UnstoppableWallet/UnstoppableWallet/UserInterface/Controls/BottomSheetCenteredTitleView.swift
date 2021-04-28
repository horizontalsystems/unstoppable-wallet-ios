import UIKit
import SnapKit
import ThemeKit

class BottomSheetCenteredTitleView: UIView {
    static let height: CGFloat = 64

    private let imageView = UIImageView()
    private let label = UILabel()
    private let separatorView = UIView()

    init() {
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(Self.height)
        }

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin12)
            maker.centerY.equalToSuperview()
        }

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        label.font = .headline2
        label.textColor = .themeOz

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var icon: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue?.withRenderingMode(.alwaysTemplate) }
    }

    var iconTintColor: UIColor? {
        get { imageView.tintColor }
        set { imageView.tintColor = newValue }
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

}
