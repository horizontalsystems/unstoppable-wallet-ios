import UIKit
import RxSwift
import RxCocoa

class SlippageViewModel {
    private let placeholderRelay = BehaviorRelay<String>(value: "0")
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let cautionTypeRelay = BehaviorRelay<CautionType>(value: .error)
    private let inputTextRelay = BehaviorRelay<String>(value: "")

    public var error: String? {
        didSet {
            cautionRelay.accept(error.map { Caution(text: $0, type: .warning) })
        }
    }

}

extension SlippageViewModel: IVerifiedInputViewModel {

    var inputFieldMaximumNumberOfLines: Int {
        0
    }
    var inputFieldInitialValue: String? {
        "abc"
    }

    var inputFieldButtonItems: [InputFieldButtonItem] {
        [
            InputFieldButtonItem(style: .secondaryIcon, icon: UIImage(named: "Send Delete Icon"), visible: .onFilled) {
                let showError = Int.random(in: 0...1) == 0
                self.error = showError ? "Error label hfskladfhjfdshflaskdf h dsflksdhfsf sdhlfksdjfh sdlfkjdashf lkdsjfh" : nil
            },
            InputFieldButtonItem(style: .secondaryDefault, title: "Second", icon: UIImage(named: "Send Delete Icon"), visible: .onFilled)
        ]
    }

    var inputFieldCautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var cautionTypeDriver: Driver<CautionType> {
        cautionTypeRelay.asDriver()
    }

    var inputTextDriver: Driver<String> {
        inputTextRelay.asDriver()
    }

    func inputFieldDidChange(text: String) {
        let showError = Int.random(in: 0...1) == 0
        self.error = showError ? "Error label hfskladfhjfdshflaskdf h dsflksdhfsf sdhlfksdjfh sdlfkjdashf lkdsjfh" : nil
    }

    func inputFieldIsValid(text: String) -> Bool {
        true
    }

}
