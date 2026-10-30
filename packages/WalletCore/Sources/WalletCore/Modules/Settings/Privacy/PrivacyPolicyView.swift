import SwiftUI

struct PrivacyPolicyView: View {
    @StateObject var viewModel: PrivacyPolicyViewModel

    init(config: PrivacyPolicyViewModel.Config) {
        _viewModel = StateObject(wrappedValue: PrivacyPolicyViewModel(config: config))
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                HighlightedTextView(text: viewModel.config.description)

                VStack(spacing: 0) {
                    ListSection {
                        statsRow()
                    }
                    ListSectionFooter(text: "settings.privacy.allow.description".localized)
                }

                VStack(spacing: 0) {
                    ListSection {
                        Cell(
                            left: {
                                Image("icon_nym").icon()
                            },
                            middle: {
                                ThemeText("settings.privacy.nym".localized, style: .body)
                            },
                            right: {
                                Image.disclosureIcon
                            },
                            action: {
                                Coordinator.shared.present(url: AppConfig.nymVpnLink)
                            }
                        )
                    }
                    ListSectionFooter(text: "settings.privacy.nym.description".localized)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings.privacy".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statsRow() -> some View {
        Cell(
            left: { ThemeImage("share", size: .iconSize24) },
            middle: { ThemeText("settings.privacy.allow".localized, style: .headline2) },
            right: { ThemeToggle(isOn: Binding(get: { viewModel.statsEnabled }, set: { viewModel.set(allowed: $0) })) }
        )
    }
}
