import UIKit
import RxSwift
import RxCocoa

class SlippageViewModel {
    private(set) var onChangeText: ((String) -> ())?
    private(set) var isValidText: ((String) -> Bool)?
    private(set) var onChangeHeight: ((CGFloat) -> ())?

    private let placeholderRelay = BehaviorRelay<String>(value: "0")
    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private let errorColorRelay = BehaviorRelay<UIColor>(value: .themeLucian)
    private let inputTextRelay = BehaviorRelay<String>(value: "")
    private let changeHeightRelay = BehaviorRelay<CGFloat>(value: 0)

    public var error: String? {
        didSet {
            errorRelay.accept(error)
        }
    }

    init() {
        onChangeText = { [weak self] in self?.inputTextRelay.accept($0) }
        isValidText = { _ in true }
        onChangeHeight = {[weak self] in
            print("change height to : \($0)")
            self?.changeHeightRelay.accept($0)
        }
    }

}

extension SlippageViewModel: IVerifiedInputViewModel {

    var maximumNumberOfLines: Int {
        0
    }

    var buttonItems: [InputFieldButtonItem] {
        [
            InputFieldButtonItem(style: .secondaryIcon, title: "Ava", icon: UIImage(named: "Send Delete Icon"), visible: .onFilled) {
                let showError = Int.random(in: 0...1) == 0
                self.error = showError ? "Error label hfskladfhjfdshflaskdf h dsflksdhfsf sdhlfksdjfh sdlfkjdashf lkdsjfh" : nil
            },
            InputFieldButtonItem(style: .secondaryDefault, title: "Second", icon: UIImage(named: "Send Delete Icon"), visible: .onFilled) {
                let showError = Int.random(in: 0...1) == 0
                self.error = showError ? "Error label hfskladfhjfdshflaskdf h dsflksdhfsf sdhlfksdjfh sdlfkjdashf lkdsjfh" : nil
            }
        ]
    }

    var placeholderDriver: Driver<String> {
        placeholderRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var errorColorDriver: Driver<UIColor> {
        errorColorRelay.asDriver()
    }

    var inputTextDriver: Driver<String> {
        inputTextRelay.asDriver()
    }

    var changeHeight: Driver<CGFloat> {
        changeHeightRelay.asDriver()
    }

}
