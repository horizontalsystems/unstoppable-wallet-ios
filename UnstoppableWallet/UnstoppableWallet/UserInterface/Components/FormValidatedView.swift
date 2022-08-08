import UIKit
import ThemeKit
import SnapKit

class FormValidatedView: UIView {
    private let wrapperView = UIView()
    private let contentView: IHeightControlView
    private let padding: UIEdgeInsets

    init(contentView: IHeightControlView, padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16)) {
        self.contentView = contentView
        self.padding = padding

        super.init(frame: .zero)

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(padding)
        }

        wrapperView.backgroundColor = .themeLawrence
        wrapperView.layer.cornerRadius = .cornerRadius8
        wrapperView.layer.cornerCurve = .continuous
        wrapperView.layer.borderWidth = CGFloat.heightOneDp
        wrapperView.layer.borderColor = UIColor.themeSteel20.cgColor

        wrapperView.addSubview(contentView)
        contentView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FormValidatedView {

    func set(cautionType: CautionType?) {
        let borderColor: UIColor

        if let cautionType = cautionType {
            borderColor = cautionType.borderColor
        } else {
            borderColor = .themeSteel20
        }

        wrapperView.layer.borderColor = borderColor.cgColor
    }

    var onChangeHeight: (() -> ())? {
        get { contentView.onChangeHeight }
        set { contentView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        let contentViewWidth = containerWidth - padding.width
        let contentViewHeight = contentView.height(containerWidth: contentViewWidth)

        return contentViewHeight + padding.height
    }

}

protocol IHeightControlView: UIView {
    var onChangeHeight: (() -> ())? { get set }
    func height(containerWidth: CGFloat) -> CGFloat
}
