import UIKit

class BasePerformanceCollectionViewCell: UICollectionViewCell {
    private let topSeparator = UIView()
    private let leftSeparator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        contentView.addSubview(topSeparator)
        topSeparator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1)
        }

        topSeparator.backgroundColor = .themeSteel10

        contentView.addSubview(leftSeparator)
        leftSeparator.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
            maker.width.equalTo(1)
        }

        leftSeparator.backgroundColor = .themeSteel10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(horizontalFirst: Bool, verticalFirst: Bool) {
        leftSeparator.isHidden = horizontalFirst
        topSeparator.isHidden = verticalFirst
    }

}
