import LocalAuthentication
import SwiftUI

struct DuressModeIntroView: View {
    let viewModel: DuressModeViewModel
    @Binding var showParentSheet: Bool

    @State private var nextPresented = false

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 0) {
                        PageDescription(text: "enable_duress_mode.intro.description".localized)

                        VStack(spacing: 0) {
                            ListSectionHeader(text: "enable_duress_mode.intro.notes".localized)
                            ListSection {
                                if let biometryType = viewModel.biometryType {
                                    InfoRow(
                                        icon: biometryType.iconName,
                                        title: biometryType.title,
                                        description: "enable_duress_mode.intro.biometrics.description".localized(biometryType.title, biometryType.title)
                                    )
                                }

                                InfoRow(
                                    icon: "dialpad",
                                    title: "enable_duress_mode.intro.passcode_disabling".localized,
                                    description: "enable_duress_mode.intro.passcode_disabling.description".localized
                                )

                                InfoRow(
                                    icon: "pen",
                                    title: "enable_duress_mode.intro.passcode_change".localized,
                                    description: "enable_duress_mode.intro.passcode_change.description".localized
                                )
                            }
                            .themeListStyle(.bordered)
                        }
                        .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
                    }
                }
            } bottomContent: {
                ThemeButton(text: "button.continue".localized) {
                    nextPresented = true
                }
            }
        }
        .navigationTitle("enable_duress_mode.intro.title".localized)
        .navigationDestination(isPresented: $nextPresented) {
            if (viewModel.regularAccounts + viewModel.watchAccounts).isEmpty {
                CreatePasscodeModule.createDuressPasscodeView(accountIds: [], showParentSheet: $showParentSheet)
            } else {
                DuressModeSelectView(viewModel: viewModel, showParentSheet: $showParentSheet)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    showParentSheet = false
                }) {
                    Image("close")
                }
            }
        }
    }

    private struct InfoRow: View {
        let icon: String
        let title: String
        let description: String

        var body: some View {
            Cell(
                left: { ThemeImage(icon, size: .iconSize24, colorStyle: .brand) },
                middle: { MultiText(title: title, subtitle: description) }
            )
        }
    }
}
