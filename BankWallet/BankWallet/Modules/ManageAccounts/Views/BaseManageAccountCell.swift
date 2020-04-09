import UIKit
import SnapKit

class BaseManageAccountCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin4x

    private let selectAnimationDuration = 0.3

    private let borderLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()

    let contentHolder = UIView()
    private let separatorView = UIView()
    private let selectView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        addSubview(contentHolder)
        contentHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(BaseManageAccountCell.horizontalMargin)
            maker.top.bottom.equalToSuperview()
        }
        contentHolder.backgroundColor = .themeLawrence

        contentHolder.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }

        separatorView.backgroundColor = .themeSteel20

        contentHolder.addSubview(selectView)
        selectView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(separatorView)
        }

        selectView.backgroundColor = .themeSteel20
        selectView.alpha = 0

        borderLayer.lineWidth = 1
        borderLayer.fillColor = UIColor.clear.cgColor

        contentHolder.layer.addSublayer(borderLayer)
        contentHolder.layer.mask = maskLayer
        contentHolder.clipsToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(position: CellPosition, highlighted: Bool, height: CGFloat) {
        let shift: CGFloat = 0.5
        let width = bounds.width - .margin4x * 2

        switch position {
        case .top:
            borderLayer.path = topPath(height: height, width: width, shift: shift).cgPath
            maskLayer.path = topPath(height: height, width: width, shift: 0).cgPath
        case .inbetween:
            borderLayer.path = sidePath(height: height, width: width, shift: shift).cgPath
            maskLayer.path = sidePath(height: height, width: width, shift: 0).cgPath
        case .bottom:
            borderLayer.path = bottomPath(height: height, width: width, shift: shift).cgPath
            maskLayer.path = bottomPath(height: height, width: width, shift: 0).cgPath
        }

        separatorView.snp.updateConstraints { maker in
            maker.height.equalTo(position == .top ? 0 : 1 / UIScreen.main.scale)
        }

        borderLayer.strokeColor = highlighted ? UIColor.themeYellowD.cgColor : UIColor.clear.cgColor
    }

    enum CellPosition {
        case top, inbetween, bottom
    }

    private func addArc(to path: UIBezierPath, center: CGPoint, startAngle: CGFloat) {
        path.addArc(
                withCenter: center,
                radius: .cornerRadius4x,
                startAngle: startAngle,
                endAngle: startAngle + CGFloat(Double.pi / 2),
                clockwise: true
        )
    }

    private func topPath(height: CGFloat, width: CGFloat, shift: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0 + shift, y: height + 5))
        path.addLine(to: CGPoint(x: 0 + shift, y: .cornerRadius4x))
        addArc(to: path, center: CGPoint(x: CGFloat.cornerRadius4x + shift, y: .cornerRadius4x + shift), startAngle: CGFloat(Double.pi))
        path.addLine(to: CGPoint(x: width - .cornerRadius4x - shift, y: shift))
        addArc(to: path, center: CGPoint(x: width - .cornerRadius4x - shift, y: .cornerRadius4x + shift), startAngle: CGFloat(Double.pi + Double.pi / 2))
        path.addLine(to: CGPoint(x: width - shift, y: height + 5))

        return path
    }

    private func sidePath(height: CGFloat, width: CGFloat, shift: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: shift, y: height + 5))
        path.addLine(to: CGPoint(x: shift, y: -5))
        path.addLine(to: CGPoint(x: width - shift, y: -5))
        path.addLine(to: CGPoint(x: width - shift, y: height + 5))

        return path
    }

    private func bottomPath(height: CGFloat, width: CGFloat, shift: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width - shift, y: 0))
        path.addLine(to: CGPoint(x: width - shift, y: height - .cornerRadius4x - shift))
        addArc(to: path, center: CGPoint(x: width - CGFloat.cornerRadius4x - shift, y: height - .cornerRadius4x - shift), startAngle: 0)
        path.addLine(to: CGPoint(x: .cornerRadius4x + shift, y: height - shift))
        addArc(to: path, center: CGPoint(x: .cornerRadius4x + shift, y: height - .cornerRadius4x - shift), startAngle: CGFloat(Double.pi / 2))
        path.addLine(to: CGPoint(x: shift, y: 0))

        return path
    }

    override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }

        if animated {
            UIView.animate(withDuration: selectAnimationDuration) {
                self.selectView.alpha = highlighted ? 1 : 0
            }
        } else {
            selectView.alpha = highlighted ? 1 : 0
        }
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }

        if animated {
            UIView.animate(withDuration: selectAnimationDuration) {
                self.selectView.alpha = selected ? 1 : 0
            }
        } else {
            selectView.alpha = selected ? 1 : 0
        }
    }

}

extension BaseManageAccountCell {

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        containerWidth - horizontalMargin * 2
    }

}
