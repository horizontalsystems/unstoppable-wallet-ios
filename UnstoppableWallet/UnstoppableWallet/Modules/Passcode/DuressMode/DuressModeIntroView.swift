import LocalAuthentication
import SwiftUI

struct DuressModeIntroView: View {
    let viewModel: DuressModeViewModel
    @Binding var showParentSheet: Bool

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: 0) {
                    PageDescription(text: "enable_duress_mode.intro.description".localized)

                    VStack(spacing: 0) {
                        ListSectionHeader(text: "enable_duress_mode.intro.notes".localized)
                        ListSection {
                            if let biometryType = viewModel.biometryType {
                                InfoRow(
                                    icon: Image(biometryType.iconName),
                                    title: biometryType.title,
                                    description: "enable_duress_mode.intro.biometrics.description".localized(biometryType.title, biometryType.title)
                                )
                            }

                            InfoRow(
                                icon: Image("dialpad_alt_2_24"),
                                title: "enable_duress_mode.intro.passcode_disabling".localized,
                                description: "enable_duress_mode.intro.passcode_disabling.description".localized
                            )

                            InfoRow(
                                icon: Image("edit_24"),
                                title: "enable_duress_mode.intro.passcode_change".localized,
                                description: "enable_duress_mode.intro.passcode_change.description".localized
                            )
                        }
                        .listStyle(.bordered)
                    }
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            } bottomContent: {
                NavigationLink(destination: {
                    if (viewModel.regularAccounts + viewModel.watchAccounts).isEmpty {
                        CreatePasscodeModule.createDuressPasscodeView(accountIds: [], showParentSheet: $showParentSheet)
                    } else {
                        DuressModeSelectView(viewModel: viewModel, showParentSheet: $showParentSheet)
                    }
                }) {
                    Text("button.continue".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .navigationTitle("enable_duress_mode.intro.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.cancel".localized) {
                showParentSheet = false
            }
        }
    }

    private struct InfoRow: View {
        let icon: Image
        let title: String
        let description: String

        var body: some View {
            ListRow {
                icon.themeIcon(color: .themeJacob)

                VStack(spacing: .margin4) {
                    Text(title).themeBody()
                    Text(description).themeSubhead2()
                }
            }
        }
    }
}
