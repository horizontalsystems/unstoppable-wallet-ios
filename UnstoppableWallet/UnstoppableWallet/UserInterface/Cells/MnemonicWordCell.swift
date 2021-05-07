import UIKit

class MnemonicWordCell: UICollectionViewCell {
    private let indexLabel = UILabel()
    private let wordLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(indexLabel)
        indexLabel.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
            maker.width.equalTo(32)
        }

        indexLabel.font = .headline2
        indexLabel.textColor = .themeGray

        contentView.addSubview(wordLabel)

        wordLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(indexLabel.snp.trailing).offset(CGFloat.margin4)
            maker.trailing.centerY.equalToSuperview()
        }

        wordLabel.font = .headline2
        wordLabel.textColor = .themeOz
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(index: Int, word: String) {
        indexLabel.text = "\(index)."
        wordLabel.text = word
    }

}
