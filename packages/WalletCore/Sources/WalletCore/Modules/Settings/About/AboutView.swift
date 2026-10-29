import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: AboutViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                if let releaseNotesUrl = viewModel.releaseNotesUrl {
                    ListSection {
                        NavigationLink(destination: {
                            ReleaseNotesView(url: releaseNotesUrl)
                                .onFirstAppear { stat(page: .aboutApp, event: .open(page: .whatsNews)) }
                        }) {
                            Cell(
                                left: { ThemeImage("information", size: .iconSize24) },
                                middle: { ThemeText("settings.about_app.app_version".localized, style: .headline2) },
                                right: {
                                    ThemeText(viewModel.appVersion, style: .subheadSB).arrow(style: .disclosure)
                                }
                            )
                        }
                        .buttonStyle(CellButtonStyle())
                    }
                }

                ListSection {
                    NavigationLink(destination: {
                        AppStatusView()
                            .onFirstAppear { stat(page: .aboutApp, event: .open(page: .appStatus)) }
                    }) {
                        Cell(
                            left: { ThemeImage("app_status", size: .iconSize24) },
                            middle: { ThemeText("app_status.title".localized, style: .headline2) },
                            right: { Image.disclosureIcon }
                        )
                    }
                    .buttonStyle(CellButtonStyle())

                    Cell(
                        left: { ThemeImage("list", size: .iconSize24) },
                        middle: { ThemeText("terms.title".localized, style: .headline2) },
                        right: { Image.disclosure(alert: viewModel.termsAlert) },
                        action: {
                            Coordinator.shared.present { isPresented in
                                TermsView(isPresented: isPresented)
                            }
                            stat(page: .aboutApp, event: .open(page: .terms))
                        }
                    )
                }

                ListSection {
                    Cell(
                        left: { ThemeImage("github", size: .iconSize24) },
                        middle: { ThemeText("GitHub", style: .headline2) },
                        right: { Image.disclosureIcon },
                        action: {
                            Coordinator.shared.present(url: "https://github.com/\(AppConfig.appGitHubAccount)/\(AppConfig.appGitHubRepository)")
                            stat(page: .aboutApp, event: .open(page: .externalGithub))
                        }
                    )

                    Cell(
                        left: { ThemeImage("globe", size: .iconSize24) },
                        middle: { ThemeText("settings.about_app.website".localized, style: .headline2) },
                        right: { Image.disclosureIcon },
                        action: {
                            Coordinator.shared.present(url: AppConfig.appWebPageLink)
                            stat(page: .aboutApp, event: .open(page: .externalWebsite))
                        }
                    )
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings.about_app.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
