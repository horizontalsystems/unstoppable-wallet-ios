import UIKit
import SnapKit
import ThemeKit

class BottomSheetTitleView: UIView {
    static let height: CGFloat = 72

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()

    var onTapClose: (() -> ())?

    init() {
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(BottomSheetTitleView.height)
        }

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin32)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize24)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeLeah

        addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize24 + 2 * CGFloat.margin8)
        }

        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        closeButton.setImage(UIImage(named: "close_3_24"), for: .normal)
        closeButton.addTarget(self, action: #selector(_onTapClose), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapClose() {
        onTapClose?()
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    func set(imageUrl: String?, placeholder: UIImage?) {
        imageView.tintColor = nil
        imageView.kf.setImage(with: imageUrl.flatMap { URL(string: $0) }, placeholder: placeholder, options: [.scaleFactor(UIScreen.main.scale)])
    }

}
