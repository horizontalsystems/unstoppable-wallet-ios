import UIKit
import SnapKit

class NumPad: UICollectionView {

    enum Cell {
        case number(number: String, letters: String?, action: () -> ())
        case image(image: UIImage?, pressedImage: UIImage?, action: (() -> ())?)
    }

    weak var numPadDelegate: NumPadDelegate?
    let layout = UICollectionViewFlowLayout()

    var cells = [Cell]()

    init() {
        super.init(frame: .zero, collectionViewLayout: layout)

        dataSource = self
        delegate = self

        layout.itemSize = NumPadTheme.itemSize
        layout.minimumLineSpacing = NumPadTheme.spacing
        layout.minimumInteritemSpacing = NumPadTheme.spacing

        register(NumPadNumberCell.self, forCellWithReuseIdentifier: String(describing: NumPadNumberCell.self))
        register(NumPadImageCell.self, forCellWithReuseIdentifier: String(describing: NumPadImageCell.self))

        backgroundColor = .clear

        isScrollEnabled = false

        snp.makeConstraints { maker in
            maker.width.equalTo(NumPadTheme.width)
            maker.height.equalTo(NumPadTheme.height)
        }

        cells = [
            .number(number: "1", letters: "", action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "1") }),
            .number(number: "2", letters: "A B C".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "2") }),
            .number(number: "3", letters: "D E F".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "3") }),
            .number(number: "4", letters: "G H I".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "4") }),
            .number(number: "5", letters: "J K L".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "5") }),
            .number(number: "6", letters: "M N O".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "6") }),
            .number(number: "7", letters: "P Q R S".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "7") }),
            .number(number: "8", letters: "T U V".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "8") }),
            .number(number: "9", letters: "W X Y Z".localized, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "9") }),
            .image(image: nil, pressedImage: nil, action: nil),
            .number(number: "0", letters: nil, action: { [weak self] in self?.numPadDelegate?.numPadDidClick(digit: "0") }),
            .image(image: UIImage(named: "Backspace Icon"), pressedImage: UIImage(named: "Backspace Icon Pressed"), action: { [weak self] in self?.numPadDelegate?.numPadDidClickBackspace() })
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

class NumPadNumberCell: UICollectionViewCell {

    let button = RespondButton()
    let numberLabel = UILabel()
    let lettersLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        button.borderWidth = NumPadTheme.itemBorderWidth
        button.borderColor = NumPadTheme.itemBorderColor
        button.titleLabel.removeFromSuperview()
        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        button.cornerRadius = NumPadTheme.itemCornerRadius
        button.backgrounds = ButtonTheme.numPadBackgroundDictionary

        numberLabel.font = NumPadTheme.numberFont
        numberLabel.textColor = NumPadTheme.numberColor
        button.addSubview(numberLabel)

        lettersLabel.font = NumPadTheme.lettersFont
        lettersLabel.textColor = NumPadTheme.lettersColor
        button.addSubview(lettersLabel)
        lettersLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-NumPadTheme.lettersBottomMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(number: String, letters: String?, onTap: @escaping () -> ()) {
        numberLabel.text = number
        lettersLabel.text = letters
        button.onTap = onTap

        lettersLabel.isHidden = letters == nil

        numberLabel.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()

            if letters == nil {
                maker.centerY.equalToSuperview()
            } else {
                maker.top.equalToSuperview().offset(NumPadTheme.numberTopMargin)
            }
        }
    }

}

class NumPadImageCell: UICollectionViewCell {

    let button = UIButton()
    var onTap: (() -> ())?

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

extension UIImage {

    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        color.set()
        withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

}

protocol NumPadDelegate: class {
    func numPadDidClick(digit: String)
    func numPadDidClickBackspace()
}
