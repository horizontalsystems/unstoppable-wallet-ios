import Foundation
import Combine

class WalletConnectBottomSheetViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    let contents = [
        "Hello World...!",
        "This is a much longer text that should appear after 5 seconds. It can be as long as you need it to be, with multiple sentences and detailed information."
    ]
 
    var index = 0
    @Published var content: String
    @Published var state: DefenseMessageModule.State  = .loading
    
    init() {
        content = contents[index]
    }
    
    func changeContent() {
        let newIndex = (index + 1) % contents.count
        self.content = contents[newIndex]
        self.state = DefenseMessageModule.State.init(rawValue: newIndex) ?? .notAvailable
        index = newIndex
    }
}
