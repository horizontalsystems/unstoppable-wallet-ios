import UIKit
import SnapKit

open class NewTopDescriptionView: UIView {
    private static let sideMargin: CGFloat = .margin4x
    private static let topMargin: CGFloat = .margin3x
    private static let bottomMargin: CGFloat = .margin6x
    private static let font: UIFont = .subhead2
    private static let sidePadding: CGFloat = .margin3x
    private static let verticalPadding: CGFloat = .margin2x

    private let label = UILabel()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        let holder = UIView()

        addSubview(holder)
        holder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(NewTopDescriptionView.sideMargin)
            maker.top.equalToSuperview().offset(NewTopDescriptionView.topMargin)
            maker.bottom.equalToSuperview().inset(NewTopDescriptionView.bottomMargin)
        }

        holder.backgroundColor = .themeLawrence
        holder.borderColor = .themeJacob
        holder.borderWidth = 1
        holder.cornerRadius = .cornerRadius2x

        holder.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(NewTopDescriptionView.sidePadding)
            maker.top.bottom.equalToSuperview().inset(NewTopDescriptionView.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = NewTopDescriptionView.font
        label.textColor = .themeJacob
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(text: String?) {
        label.text = text
    }

}

extension NewTopDescriptionView {

    public static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * NewTopDescriptionView.sideMargin - 2 * NewTopDescriptionView.sidePadding, font: NewTopDescriptionView.font)
        return textHeight + NewTopDescriptionView.topMargin + NewTopDescriptionView.bottomMargin  + 2 * NewTopDescriptionView.verticalPadding
    }

}
