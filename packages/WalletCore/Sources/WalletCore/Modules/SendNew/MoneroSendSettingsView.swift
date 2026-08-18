import Combine
import Foundation
import SwiftUI

struct MoneroSendSettingsView: View {
    @StateObject var viewModel: MoneroSendSettingsViewModel
    var onChangeSettings: () -> Void

    @State private var path = NavigationPath()

    @Environment(\.presentationMode) private var presentationMode

    init(handler: MoneroPreSendHandler, onChangeSettings: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: MoneroSendSettingsViewModel(handler: handler))
        self.onChangeSettings = onChangeSettings
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ScrollableThemeView {
                VStack(spacing: .margin32) {
                    VStack(spacing: 0) {
                        ListSection {
                            Cell(
                                middle: {
                                    MultiText(title: "send.unspent_outputs".localized, subtitle: "send.unspent_outputs.description".localized)
                                },
                                right: {
                                    ThemeText(
                                        viewModel.utxos,
                                        style: .subheadSB,
                                        colorStyle: .primary
                                    )
                                    .arrow(
                                        style: .dropdown,
                                        colorStyle: .primary
                                    )
                                },
                                action: {
                                    path.append(Route.outputSelector)
                                }
                            )
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationTitle("fee_settings".localized)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .outputSelector:
                    MoneroOutputSelectorView(handler: viewModel.handler)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.reset()
                    }) {
                        Image("reset")
                    }
                    .disabled(!viewModel.resetEnabled)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onChangeSettings()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("check")
                    }
                    .modifier(ConfirmationButtonStyle())
                }
            }
        }
    }
}

extension MoneroSendSettingsView {
    private enum Route: Hashable {
        case outputSelector
    }
}

class MoneroSendSettingsViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    let handler: MoneroPreSendHandler

    @Published var resetEnabled: Bool
    @Published var utxos: String = ""

    init(handler: MoneroPreSendHandler) {
        self.handler = handler

        resetEnabled = handler.settingsModified

        handler.settingsModifiedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.resetEnabled = $0 }
            .store(in: &cancellables)

        handler.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.syncUtxos() }
            .store(in: &cancellables)

        syncUtxos()
    }

    private func syncUtxos() {
        let totalUtxos = handler.allOutputs.count
        let usedUtxos = handler.customOutputs?.count ?? totalUtxos

        utxos = [usedUtxos.description, totalUtxos.description].joined(separator: " / ")
    }

    func reset() {
        handler.customOutputs = nil
        resetEnabled = handler.settingsModified
    }
}
