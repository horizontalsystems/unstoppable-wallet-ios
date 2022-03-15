import Foundation

class SendXFeePriorityModule {

    static func viewModel(service: SendXFeePriorityService) -> SendXFeePriorityViewModel {
        SendXFeePriorityViewModel(service: service)
    }

}
