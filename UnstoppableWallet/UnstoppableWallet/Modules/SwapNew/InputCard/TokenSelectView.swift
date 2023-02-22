import Foundation
import UIKit
import ComponentKit
import ThemeKit

class TokenSelectView: UIView {
    let wrapperButton = UIButton()
    let tokenImage = ImageComponent(size: .iconSize32)

    let tokenButton = SecondaryButton()

    var onTap: (() -> ())?

    init() {
        super.init(frame: .zero)

        addSubview(wrapperButton)
        wrapperButton.snp.makeConstraints { maker in
            maker.top.leading.bottom.equalToSuperview()
        }

        wrapperButton.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        wrapperButton.addSubview(tokenImage)
        tokenImage.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.trailing.centerY.equalToSuperview()
        }

        addSubview(tokenButton)
        tokenButton.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(wrapperButton.snp.trailing).offset(-CGFloat.margin8)
            maker.trailing.equalToSuperview()
        }

        tokenButton.set(style: .transparent, image: UIImage(named: "arrow_small_down_20"))
        tokenButton.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        tokenButton.setContentHuggingPriority(.required, for: .horizontal)
        tokenButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

}
