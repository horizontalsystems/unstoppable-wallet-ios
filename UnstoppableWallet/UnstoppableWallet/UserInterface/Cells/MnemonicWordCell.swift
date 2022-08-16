import UIKit
import ComponentKit

class MnemonicWordCell: UICollectionViewCell {
    private static let indexFont: UIFont = .subhead1
    private static let wordFont: UIFont = .body
    private static let spacing: CGFloat = .margin6

    private let indexText = TextComponent()
    private let wordText = TextComponent()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView()

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.alignment = .lastBaseline
        stackView.spacing = Self.spacing

        stackView.addArrangedSubview(indexText)

        indexText.font = Self.indexFont
        indexText.textColor = .themeGray50

        stackView.addArrangedSubview(wordText)

        wordText.font = Self.wordFont
        wordText.textColor = .themeLeah
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(index: Int, word: String) {
        indexText.text = "\(index)"
        wordText.text = word
    }

}

extension MnemonicWordCell {

    static func size(index: Int, word: String) -> CGSize {
        let indexSize = "\(index)".size(containerWidth: .greatestFiniteMagnitude, font: indexFont)
        let wordSize = word.size(containerWidth: .greatestFiniteMagnitude, font: wordFont)

        return CGSize(
                width: indexSize.width + spacing + wordSize.width,
                height: max(indexSize.height, wordSize.height)
        )
    }

}
