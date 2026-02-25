import SwiftUI

struct BackupView: View {
    @StateObject private var viewModel: BackupViewModel
    @Binding var isPresented: Bool
    @State private var path = NavigationPath()

    init(type: BackupModule.BackupType, destination: BackupModule.Destination? = nil, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: BackupViewModel(type: type, destination: destination))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            stepView(for: viewModel.initialStep)
                .navigationDestination(for: BackupModule.Step.self) { step in
                    stepView(for: step)
                }
        }
        .onReceive(viewModel.dismissPublisher) {
            isPresented = false
        }
        .onReceive(viewModel.sharePublisher) { url in
            Coordinator.shared.present { _ in
                ActivityView(activityItems: [url], completionWithItemsHandler: { _, success, _, error in
                    if success {
                        viewModel.handleSuccessShared()
                    } else if let error {
                        viewModel.handleShareError(error)
                    }
                })
            }
        }
        .onReceive(viewModel.errorPublisher) { error in
            HudHelper.instance.show(banner: .error(string: error))
        }
    }

    @ViewBuilder
    private func stepView(for step: BackupModule.Step) -> some View {
        switch step {
        case .selectDestination:
            BackupSelectDestinationView(viewModel: viewModel, path: $path)
        case .selectContent:
            BackupSelectContentView(viewModel: viewModel, path: $path)
        case .disclaimer:
            BackupDisclaimerView(viewModel: viewModel, path: $path)
        case .form:
            BackupFormView(viewModel: viewModel, path: $path)
        }
    }
}
