import RxSwift
import RxRelay
import RxCocoa

class TermsViewModel {
    private let termCount = 6

    private let service: TermsService

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let buttonEnabledRelay = BehaviorRelay<Bool>(value: false)
    private var checkedIndices = Set<Int>()

    init(service: TermsService) {
        self.service = service

        if service.termsAccepted {
            (0..<termCount).forEach { checkedIndices.insert($0) }
        }

        syncState()
    }

    private func syncState() {
        let viewItems = (0..<termCount).map { index in
            ViewItem(text: "terms.item.\(index + 1)".localized, checked: checkedIndices.contains(index))
        }

        viewItemsRelay.accept(viewItems)

        buttonEnabledRelay.accept(checkedIndices.count == termCount)
    }

}

extension TermsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var buttonEnabledDriver: Driver<Bool> {
        buttonEnabledRelay.asDriver()
    }

    var buttonVisible: Bool {
        !service.termsAccepted
    }

    func onToggle(index: Int) {
        if checkedIndices.contains(index) {
            checkedIndices.remove(index)
        } else {
            checkedIndices.insert(index)
        }

        syncState()
    }

    func onTapAgree() {
        service.setTermsAccepted()
    }

}

extension TermsViewModel {

    struct ViewItem {
        let text: String
        let checked: Bool
    }

}
