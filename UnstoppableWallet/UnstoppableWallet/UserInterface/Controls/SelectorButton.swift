import Foundation
import UIKit
import ComponentKit

class SelectorButton: SecondaryButton {
    private var items = [String]()

    var currentIndex: Int = 0
    var onSelect: ((Int) -> ())?

    private func imageName(count: Int, index: Int) -> String { "mode_\(count)_\(index + 1)_20" }

    override init() {
        super.init()

        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(items: [String]) {
        set(style: .default)

        self.items = items

        guard !items.isEmpty else {
            setTitle(nil, for: .normal)
            return
        }

        setSelected(index: 0, initial: true)
    }

    @objc private func onTap() {
        guard !items.isEmpty else {
            return
        }

        let nextIndex = (currentIndex + 1) % items.count
        setSelected(index: nextIndex, initial: false)
    }

    private func setSelected(index: Int, initial: Bool) {
        guard index < items.count, initial || currentIndex != index else {
            return
        }

        setTitle(items[index], for: .normal)
        setImage(UIImage(named: imageName(count: items.count, index: index)), for: .normal)
        syncInsets()

        currentIndex = index

        if !initial {
            onSelect?(index)
        }
    }

    public func setSelected(index: Int) {
        setSelected(index: index, initial: true)
    }

}
