import Foundation

class MemoInputViewModel {
    private let service: MemoInputService

    init(service: MemoInputService) {
        self.service = service
    }

}

extension MemoInputViewModel {

    func change(text: String?) {
        service.set(text: text)
    }

    func isValid(text: String) -> Bool {
        service.isValid(text: text)
    }

}
