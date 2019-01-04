import UIKit
import SnapKit

class NumPad: UICollectionView {

    private enum Cell {
        case number(number: String, letters: String?, action: () -> ())
        case image(image: UIImage?, pressedImage: UIImage?, action: (() -> ())?)
    }

    public struct Style: OptionSet {
        let rawValue: Int

        public static let decimal = Style(rawValue: 1 << 1)
        public static let letters = Style(rawValue: 1 << 2)
    }

    weak var numPadDelegate: NumPadDelegate?
    private let layout = UICollectionViewFlowLayout()

    private var cells = [Cell]()

    private var style: Style

    init(style: Style = []) {
        self.style = style

        super.init(frame: .zero, collectionViewLayout: layout)

        dataSource = self
        delegate = self

        layout.minimumInteritemSpacing = NumPadTheme.itemSpacing
        layout.minimumLineSpacing = NumPadTheme.lineSpacing

        register(NumPadNumberCell.self, forCellWithReuseIdentifier: String(describing: NumPadNumberCell.self))
        register(NumPadImageCell.self, forCellWithReuseIdentifier: String(describing: NumPadImageCell.self))

        backgroundColor = .clear

        isScrollEnabled = false

        snp.makeConstraints { maker in
            maker.size.equalTo(NumPadTheme.size)
        }

        cells.append(.number(number: "1", letters: style.contains(.letters) ? "" : nil, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "1") }))
        for i in 2...9 {
            cells.append(.number(number: "\(i)", letters: letters(for: i), action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "\(i)") }))
        }
        if style.contains(.decimal) {
            cells.append(.image(image: UIImage(named: "Decimal Dot"), pressedImage: UIImage(named: "Decimal Dot"), action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: ".") }))
        } else {
            cells.append(.image(image: nil, pressedImage: nil, action: nil))
        }
        cells.append(.number(number: "0", letters: nil, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "0") }))
        cells.append(.image(image: UIImage(named: "Backspace Icon"), pressedImage: UIImage(named: "Backspace Icon Pressed"), action: { [weak self] in self?.numPadDelegate?.numPadDidClickBackspace() }))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func letters(for index: Int) -> String? {
        return style.contains(.letters) ? "numpad_\(index)".localized : nil
    }

}

extension NumPad: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cells.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier: String

        switch cells[indexPath.item] {
        case .number: identifier = String(describing: NumPadNumberCell.self)
        case .image: identifier = String(describing: NumPadImageCell.self)
        }

        return dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }

}

extension NumPad: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch cells[indexPath.item] {
        case .number(let number, let letters, let action):
            if let cell = cell as? NumPadNumberCell {
                cell.bind(number: number, letters: letters, onTap: action)
            }
        case .image(let image, let pressedImage, let action):
            if let cell = cell as? NumPadImageCell {
                cell.bind(image: image, pressedImage: pressedImage, onTap: action)
            }
        }
    }

}

extension NumPad: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (bounds.size.width - NumPadTheme.itemSpacing * 2) / 3, height: NumPadTheme.itemHeight)
    }

}

class NumPadNumberCell: UICollectionViewCell {

    private let button = UIButton()
    private let numberLabel = UILabel()
    private let lettersLabel = UILabel()
    private var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        button.borderWidth = NumPadTheme.itemBorderWidth
        button.borderColor = NumPadTheme.itemBorderColor
        button.cornerRadius = NumPadTheme.itemCornerRadius
        button.setBackgroundColor(color: NumPadTheme.buttonBackgroundColor, forState: .normal)
        button.setBackgroundColor(color: NumPadTheme.buttonBackgroundColorHighlighted, forState: .highlighted)
        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        numberLabel.font = NumPadTheme.numberFont
        numberLabel.textColor = NumPadTheme.numberColor
        button.addSubview(numberLabel)

        lettersLabel.font = NumPadTheme.lettersFont
        lettersLabel.textColor = NumPadTheme.lettersColor
        button.addSubview(lettersLabel)
        lettersLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(numberLabel.snp.bottom)
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(number: String, letters: String?, onTap: @escaping () -> ()) {
        numberLabel.text = number
        lettersLabel.text = letters
        self.onTap = onTap

        lettersLabel.isHidden = letters == nil

        numberLabel.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()

            if letters == nil {
                maker.top.equalToSuperview().offset(NumPadTheme.numberTopMargin)
            } else {
                maker.top.equalToSuperview().offset(NumPadTheme.letteredNumberTopMargin)
            }
        }
    }

    @objc func didTapButton() {
        onTap?()
    }

}

class NumPadImageCell: UICollectionViewCell {

    private let button = UIButton()
    private var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(image: UIImage?, pressedImage: UIImage?, onTap: (() -> ())?) {
        self.onTap = onTap
        button.setImage(image?.tinted(with: .crypto_White_Black), for: .normal)
        button.setImage(pressedImage?.tinted(with: .crypto_White_Black), for: .highlighted)
    }

    @objc func didTapButton() {
        onTap?()
    }

}

protocol NumPadDelegate: class {
    func numPadDidClick(digit: String)
    func numPadDidClickBackspace()
}
