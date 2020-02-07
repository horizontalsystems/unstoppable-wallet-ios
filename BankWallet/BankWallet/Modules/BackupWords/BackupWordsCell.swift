import UIKit

class BackupWordsCell: UICollectionViewCell {
    static let maxWordsCount = 6

    private var indexLabels = [UILabel]()
    private var wordLabels = [UILabel]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        var lastIndexLabel: UILabel?
        var lastWordLabel: UILabel?

        for _ in 0..<BackupWordsCell.maxWordsCount {
            let indexLabel = UILabel()
            contentView.addSubview(indexLabel)

            indexLabel.snp.makeConstraints { maker in
                maker.leading.equalToSuperview()
                maker.width.equalTo(32)
                if let lastIndexLabel = lastIndexLabel {
                    maker.top.equalTo(lastIndexLabel.snp.bottom).offset(CGFloat.margin1x)
                } else {
                    maker.top.equalToSuperview()
                }
            }
            
            indexLabel.textColor = .themeGray
            indexLabel.font = .headline2
            lastIndexLabel = indexLabel

            indexLabels.append(indexLabel)

            let wordLabel = UILabel()
            contentView.addSubview(wordLabel)

            wordLabel.snp.makeConstraints { maker in
                maker.leading.equalTo(indexLabel.snp.trailing).offset(CGFloat.margin1x)
                maker.trailing.equalToSuperview().inset(CGFloat.margin2x)
                if let lastWordLabel = lastWordLabel {
                    maker.top.equalTo(lastWordLabel.snp.bottom).offset(CGFloat.margin1x)
                } else {
                    maker.top.equalToSuperview()
                }
            }

            wordLabel.textColor = .themeOz
            wordLabel.font = .headline2
            lastWordLabel = wordLabel

            wordLabels.append(wordLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(startIndex: Int, words: [String]) {
        for (index, word) in words.prefix(BackupWordsCell.maxWordsCount).enumerated() {
            indexLabels[index].text = "\(startIndex + index)."
            wordLabels[index].text = word
        }
    }

    static func heightFor(words: [String]) -> CGFloat {
        var height: CGFloat = 0
        let maxWords = words.prefix(BackupWordsCell.maxWordsCount)
        for word in maxWords {
            height += word.height(forContainerWidth: CGFloat.greatestFiniteMagnitude, font: .headline2)
        }
        return height + CGFloat.margin1x * CGFloat(max(0, maxWords.count - 1))
    }

}
