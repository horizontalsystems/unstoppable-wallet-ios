import UIKit
import SnapKit

class NumPad: UICollectionView {
    private let columnCount: CGFloat = 3
    private let rowCount: CGFloat = 4

    private let itemSizeRatio: CGFloat = 1.2
    private let itemLineSpacingRatio: CGFloat = 5

    private enum Cell {
        case number(number: String, letters: String?, filled: Bool, action: () -> ())
        case image(image: UIImage?, pressedImage: UIImage?, action: (() -> ())?)
    }

    public struct Style: OptionSet {
        let rawValue: Int

        public static let decimal = Style(rawValue: 1 << 1)
        public static let letters = Style(rawValue: 1 << 2)
    }

    weak var numPadDelegate: NumPadDelegate?
    private let layout = UICollectionViewFlowLayout()

    private let formatter = NumberFormatter()

    private var cells = [Cell]()
    private var style: Style

    init(style: Style = []) {
        self.style = style

        super.init(frame: .zero, collectionViewLayout: layout)

        dataSource = self
        delegate = self

        formatter.numberStyle = .decimal

        register(NumPadNumberCell.self, forCellWithReuseIdentifier: String(describing: NumPadNumberCell.self))
        register(NumPadImageCell.self, forCellWithReuseIdentifier: String(describing: NumPadImageCell.self))

        backgroundColor = .clear

        isScrollEnabled = false

        let localizedOne = format(number: 1)
        cells.append(.number(number: localizedOne, letters: style.contains(.letters) ? " " : nil, filled: true, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: localizedOne) }))
        for i in 2...9 {
            let localizedNumber = format(number: i)
            cells.append(.number(number: localizedNumber, letters: letters(for: i), filled: true, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: localizedNumber) }))
        }
        if style.contains(.decimal), let decimalSeparator = formatter.decimalSeparator {
            cells.append(.number(number: decimalSeparator, letters: nil, filled: false, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: decimalSeparator) }))
        } else {
            cells.append(.image(image: nil, pressedImage: nil, action: nil))
        }
        let localizedZero = format(number: 0)
        cells.append(.number(number: localizedZero, letters: nil, filled: true, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: localizedZero) }))
        cells.append(.image(image: UIImage(named: "Backspace Icon"), pressedImage: UIImage(named: "Backspace Icon Pressed"), action: { [weak self] in self?.numPadDelegate?.numPadDidClickBackspace() }))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var itemWidth: CGFloat {
        floor(bounds.width / (columnCount * itemSizeRatio))      // Width for column count digit items
    }

    private var interitemSpacing: CGFloat {
        floor((bounds.width - columnCount * bounds.width / (columnCount * itemSizeRatio)) / (columnCount - 1)) // width witout items divided on interitem spacing count
    }

    private var lineSpacing: CGFloat {
        floor(bounds.width / (columnCount * itemSizeRatio) / itemLineSpacingRatio)   // height for line spacing
    }

    private func letters(for index: Int) -> String? {
        style.contains(.letters) ? "numpad_\(index)".localized : nil
    }

    private func format(number: Int) -> String {
        formatter.string(from: number as NSNumber) ?? ""
    }

    public func height(for width: CGFloat) -> CGFloat {
        ceil(rowCount * width / (columnCount * itemSizeRatio) + (rowCount - 1) * width / (columnCount * itemSizeRatio) /  itemLineSpacingRatio) // sum of item heights and line spacing between them
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
        case .number(let number, let letters, let filled, let action):
            if let cell = cell as? NumPadNumberCell {
                cell.bind(number: number, letters: letters, filled: filled, cornerRadius: ceil(itemWidth / 2), onTap: action)
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
        return CGSize(width: itemWidth, height: itemWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interitemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }

}

class NumPadNumberCell: UICollectionViewCell {

    private let button = UIButton()
    private let textHolderView = UIView()
    private let numberLabel = UILabel()
    private let lettersLabel = UILabel()
    private var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.borderWidth = .heightOneDp
        button.cornerRadius = 36

        button.addSubview(textHolderView)
        textHolderView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview()
            maker.trailing.lessThanOrEqualToSuperview()
        }

        textHolderView.addSubview(numberLabel)
        numberLabel.font = .title2R
        numberLabel.textColor = .themeLeah

        textHolderView.addSubview(lettersLabel)
        lettersLabel.font = .micro
        lettersLabel.textColor = .themeGray50

        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(number: String, letters: String?, filled: Bool, cornerRadius: CGFloat, onTap: @escaping () -> ()) {
        button.cornerRadius = cornerRadius
        if filled {
            button.borderColor = .themeSteel20
            button.setBackgroundColor(color: .clear, forState: .normal)
            button.setBackgroundColor(color: .themeLawrence, forState: .highlighted)
        } else {
            button.borderColor = .clear
            button.setBackgroundColor(color: .clear, forState: .normal)
            button.setBackgroundColor(color: .clear, forState: .highlighted)
        }

        numberLabel.text = number
        lettersLabel.text = letters
        self.onTap = onTap

        lettersLabel.isHidden = letters == nil

        numberLabel.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()

            if letters == nil {
                maker.centerY.equalToSuperview()
            } else {
                maker.top.equalToSuperview()
            }
        }
        lettersLabel.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()

            if letters != nil {
                maker.top.equalTo(numberLabel.snp.bottom).offset(-3)
                maker.bottom.equalToSuperview()
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
        button.setImage(image, for: .normal)
        button.setImage(pressedImage, for: .highlighted)
    }

    @objc func didTapButton() {
        onTap?()
    }

}

protocol NumPadDelegate: class {
    func numPadDidClick(digit: String)
    func numPadDidClickBackspace()
}
