import ComponentKit

class SelectorButton: ThemeButton {
    private var items = [String]()

    var currentIndex: Int = 0
    var didSetIndex: ((Int) -> ())?

    private func imageName(count: Int, index: Int) -> String { "mode_\(count)_\(index + 1)_20" }

    override init() {
        super.init()

        tinted = false
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func apply(items: [String]) {
        apply(style: .secondaryDefaultIcon)

        self.items = items

        guard !items.isEmpty else {
            setTitle(nil, for: .normal)
            return
        }

        set(index: 0, initial: true)
    }

    @objc private func onTap() {
        guard !items.isEmpty else {
            return
        }

        let nextIndex = (currentIndex + 1) % items.count
        set(index: nextIndex, initial: false)
    }

    private func set(index: Int, initial: Bool) {
        guard index < items.count, initial || currentIndex != index else {
            return
        }

        setTitle(items[index], for: .normal)
        setImage(UIImage(named: imageName(count: items.count, index: index)), for: .normal)

        currentIndex = index

        if !initial {
            didSetIndex?(index)
        }
    }

    public func set(index: Int) {
        set(index: index, initial: true)
    }

}
