import SwiftUI

struct MainSettingsView: View {
    @StateObject private var viewModel = MainSettingsViewModel()
    @Environment(\.openURL) private var openURL

    @Binding var walletConnectPresented: Bool

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin16) {
                ListSection {
                    manageWallets()
                }

                ListSection {
                    security()
                    privacy()
                    appSettings()
                    blockchainSettings()
                    dAppConnection()
                    backupManager()
                }

                ListSection {
                    contacts()
                }

                ListSection {
                    subscription()
                }

                ListSection {
                    aboutApp()
                    rateUs()
                    tellFriend()
                    faq()
                }

                ListSection {
                    vipSupport()
                }
                .modifier(ThemeListStyleModifier(themeListStyle: .borderedPremium, selected: true))

                ListSection {
                    telegram()
                    twitter()
                }

                footer()

                if viewModel.showDevTools {
                    testSwitchersSection()
                }
            }
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
    }

    private func manageWallets() -> some View {
        NavigationLink(destination: {
            ManageAccountsView(parentPresented: nil)
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .manageWallets))
                }
        }) {
            Cell(
                left: { ThemeImage("wallet", size: .iconSize24) },
                middle: { ThemeText("settings.manage_accounts".localized, style: .headline2) },
                right: { Image.disclosure(alert: viewModel.manageWalletsAlert) }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsManageWallets)
    }

    private func blockchainSettings() -> some View {
        NavigationLink(destination: {
            BlockchainSettingsModule.view()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .blockchainSettings))
                }
        }) {
            Cell(
                left: { ThemeImage("box", size: .iconSize24) },
                middle: { ThemeText("settings.blockchain_settings".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsBlockchain)
    }

    private func security() -> some View {
        NavigationLink(destination: {
            SecuritySettingsView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .security))
                }
        }) {
            Cell(
                left: { ThemeImage("shield", size: .iconSize24) },
                middle: { ThemeText("settings.security".localized, style: .headline2) },
                right: { Image.disclosure(alert: viewModel.securityAlert) }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsSecurity)
    }

    private func privacy() -> some View {
        NavigationLink(destination: {
            PrivacyPolicyView(config: .privacy)
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .privacy))
                }
        }) {
            Cell(
                left: { ThemeImage("lock", size: .iconSize24) },
                middle: { ThemeText("settings.privacy".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsPrivacy)
    }

    private func dAppConnection() -> some View {
        Cell(
            left: { ThemeImage("link", size: .iconSize24) },
            middle: { ThemeText("settings.dapp_connection".localized, style: .headline2) },
            right: {
                HStack(spacing: .margin12) {
                    if viewModel.walletConnectPendingRequestCount > 0 {
                        ThemeText("\(viewModel.walletConnectPendingRequestCount)", style: .subheadSB, colorStyle: .red)
                    }

                    Image.disclosureIcon
                }
            },
            action: {
                walletConnectPresented = true
            }
        )
        .accessibilityIdentifier(TestTags.settingsDappConnection)
    }

    private func tonConnect() -> some View {
        NavigationLink(destination: {
            TonConnectListView()
        }) {
            Cell(
                left: { ThemeImage("ton_connect", size: .iconSize24) },
                middle: { ThemeText("TON Connect", style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
    }

    private func appSettings() -> some View {
        NavigationLink(destination: {
            AppearanceView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .appearance))
                }
        }) {
            Cell(
                left: { ThemeImage("uw_logo", size: .iconSize24) },
                middle: { ThemeText("settings.appearance".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsAppSettings)
    }

    private func subscription() -> some View {
        NavigationLink(destination: {
            PurchaseListView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .subscription))
                }
        }) {
            Cell(
                left: { ThemeImage("premium", size: .iconSize24) },
                middle: { ThemeText("subscription.title".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsSubscription)
    }

    private func contacts() -> some View {
        Cell(
            left: { ThemeImage("user", size: .iconSize24) },
            middle: { ThemeText("contacts.title".localized, style: .headline2) },
            right: { Image.disclosure(alert: viewModel.iCloudUnavailable) },
            action: {
                Coordinator.shared.present { isPresented in
                    ContactBookView(mode: .edit, isPresented: isPresented)
                        .onFirstAppear {
                            stat(page: .settings, event: .open(page: .contacts))
                        }
                }
            }
        )
        .accessibilityIdentifier(TestTags.settingsContacts)
    }

    private func backupManager() -> some View {
        NavigationLink(destination: {
            BackupManagerView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .backupManager))
                }
        }) {
            Cell(
                left: { ThemeImage("cloud", size: .iconSize24) },
                middle: { ThemeText("settings.backup_manager".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsBackupManager)
    }

    private func vipSupport() -> some View {
        Cell(
            left: { ThemeImage("support", size: .iconSize24, colorStyle: .brand) },
            middle: { ThemeText("purchases.priority_support".localized, style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                Coordinator.shared.performAfterPurchase(premiumFeature: .prioritySupport, page: .settings, trigger: .vipSupport) {
                    let appUrl = URL(string: "tg://message?slug=\(AppConfig.appTelegramSupportSlug)")!
                    let webUrl = URL(string: "https://t.me/m/\(AppConfig.appTelegramSupportSlug)")!

                    if UIApplication.shared.canOpenURL(appUrl) {
                        openURL(appUrl)
                    } else {
                        Coordinator.shared.present(url: webUrl)
                    }

                    stat(page: .settings, event: .open(page: .vipSupport))
                }
            }
        )
        .accessibilityIdentifier(TestTags.settingsPrioritySupport)
    }

    private func addressChecker() -> some View {
        Cell(
            left: { ThemeImage("radar", size: .iconSize24, colorStyle: .brand) },
            middle: { ThemeText("address_checker.title".localized, style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                Coordinator.shared.performAfterPurchase(premiumFeature: .scamProtection, page: .settings, trigger: .vipSupport) {
                    Coordinator.shared.present { isPresented in
                        CheckAddressView(isPresented: isPresented)
                            .onFirstAppear {
                                stat(page: .settings, event: .open(page: .addressChecker))
                            }
                    }
                }
            }
        )
    }

    private func aboutApp() -> some View {
        NavigationLink(destination: {
            AboutModule.view()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .aboutApp))
                }
        }) {
            Cell(
                left: { ThemeImage("information", size: .iconSize24) },
                middle: { ThemeText("settings.about_app.title".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsAbout)
    }

    private func rateUs() -> some View {
        Cell(
            left: { ThemeImage("star", size: .iconSize24) },
            middle: { ThemeText("settings.rate_us".localized, style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                viewModel.rateApp()
                stat(page: .settings, event: .open(page: .rateUs))
            }
        )
        .accessibilityIdentifier(TestTags.settingsRateUs)
    }

    private func tellFriend() -> some View {
        Cell(
            left: { ThemeImage("arrow_out", size: .iconSize24) },
            middle: { ThemeText("settings.tell_friends".localized, style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                Coordinator.shared.present { _ in
                    ActivityView(activityItems: ["settings_tell_friends.text".localized + "\n" + AppConfig.appWebPageLink])
                }
                stat(page: .settings, event: .open(page: .tellFriends))
            }
        )
        .accessibilityIdentifier(TestTags.settingsTellFriends)
    }

    private func faq() -> some View {
        NavigationLink(destination: {
            FaqView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .faq))
                }
        }) {
            Cell(
                left: { ThemeImage("message", size: .iconSize24) },
                middle: { ThemeText("settings.faq".localized, style: .headline2) },
                right: { Image.disclosureIcon }
            )
        }
        .buttonStyle(CellButtonStyle())
        .accessibilityIdentifier(TestTags.settingsFaq)
    }

    private func telegram() -> some View {
        Cell(
            left: { ThemeImage("telegram_logo", size: .iconSize24) },
            middle: { ThemeText("Telegram", style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                let appUrl = URL(string: "tg://resolve?domain=\(AppConfig.appTelegramAccount)")!
                let webUrl = URL(string: "https://t.me/\(AppConfig.appTelegramAccount)")!

                if UIApplication.shared.canOpenURL(appUrl) {
                    openURL(appUrl)
                } else {
                    Coordinator.shared.present(url: webUrl)
                }

                stat(page: .settings, event: .open(page: .externalTelegram))
            }
        )
        .accessibilityIdentifier(TestTags.settingsTelegram)
    }

    private func twitter() -> some View {
        Cell(
            left: { ThemeImage("x_logo", size: .iconSize24) },
            middle: { ThemeText("X.com", style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                let account = AppConfig.appTwitterAccount

                if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
                    UIApplication.shared.open(appUrl)
                } else {
                    Coordinator.shared.present(url: "https://twitter.com/\(account)")
                }

                stat(page: .settings, event: .open(page: .externalTwitter))
            }
        )
        .accessibilityIdentifier(TestTags.settingsTwitter)
    }

    private func donate() -> some View {
        Cell(
            left: { ThemeImage("heart", size: .iconSize24) },
            middle: { ThemeText("settings.donate.title".localized, style: .headline2) },
            right: { Image.disclosureIcon },
            action: {
                Coordinator.shared.present { isPresented in
                    DonateTokenListView(isPresented: isPresented)
                }
                stat(page: .settings, event: .open(page: .donate))
            }
        )
    }

    private func footer() -> some View {
        VStack(spacing: 0) {
            ThemeText("\(AppConfig.appName) \(viewModel.appVersion)\n\("purchases.wallet_description.approved".localized)", style: .caption)
                .multilineTextAlignment(.center)
                .padding(.margin16)

            HStack(spacing: .margin8) {
                ForEach(viewModel.approvedIcons, id: \.self) { icon in
                    Image(icon)
                        .renderingMode(.template)
                        .foregroundColor(.themeGray)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: .heightCell48)
            .padding(.horizontal, .margin8)
        }
    }

    private func testSwitchersSection() -> some View {
        ListSection {
            Cell(
                middle: { ThemeText("Force Enable Swap", style: .headline2) },
                right: { ThemeToggle(isOn: $viewModel.forceEnableSwap) }
            )

            Cell(
                middle: { ThemeText("Emulate EVM Swap Send", style: .headline2) },
                right: { ThemeToggle(isOn: $viewModel.emulateEvmSwapSend) }
            )

            row(
                title: "Simulate Fail Swap",
                subtitle: "none / server / local",
                value: viewModel.simulateFailSwap.rawValue,
                identifier: TestTags.settingsDebugSimulateFailSwap,
                action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "Simulate Fail Swap",
                            viewItems: SimulateFailSwapMode.allCases.map {
                                AlertViewItem(text: $0.rawValue, selected: viewModel.simulateFailSwap == $0)
                            },
                            onSelect: { index in
                                viewModel.simulateFailSwap = SimulateFailSwapMode.allCases[index]
                            },
                            isPresented: isPresented
                        )
                    }
                }
            )

            Cell(
                middle: { ThemeText("Emulate Purchase", style: .headline2) },
                right: { ThemeToggle(isOn: $viewModel.emulatePurchase) }
            )

            Cell(
                middle: { ThemeText("TestNet Enabled", style: .headline2) },
                right: { ThemeToggle(isOn: $viewModel.testNetEnabled) }
            )

            Cell(
                middle: { ThemeText("Emulate ZEC Migration", style: .headline2) },
                right: { ThemeToggle(isOn: $viewModel.emulateZcashMigration) }
            )

            row(
                title: "AML checking result".localized,
                subtitle: "Override checking result from server".localized,
                value: viewModel.debuggingAmlResult?.rawValue ?? "clear",
                action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "AML Result".localized,
                            viewItems: [.init(text: "clear".localized, selected: viewModel.debuggingAmlResult == nil)] +
                                MultiSwapViewModel.AmlRiskResult.allCases.map {
                                    AlertViewItem(text: $0.rawValue, selected: viewModel.debuggingAmlResult == $0)
                                },
                            onSelect: { index in
                                switch index {
                                case 0: viewModel.debuggingAmlResult = nil
                                default: viewModel.debuggingAmlResult = MultiSwapViewModel.AmlRiskResult.allCases[index - 1]
                                }
                            },
                            isPresented: isPresented
                        )
                    }
                }
            )

            // Temporary dev switch; replaced by the Appearance brand color picker
            row(
                title: "Brand Color",
                subtitle: BrandColor.allCases.map(\.rawValue).joined(separator: " / "),
                value: viewModel.brandColor.rawValue,
                identifier: TestTags.settingsDebugBrandColor,
                action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "Brand Color",
                            viewItems: BrandColor.allCases.map {
                                AlertViewItem(text: $0.rawValue, selected: viewModel.brandColor == $0)
                            },
                            onSelect: { index in
                                viewModel.brandColor = BrandColor.allCases[index]
                            },
                            isPresented: isPresented
                        )
                    }
                }
            )
        }
    }

    private func row(title: String, subtitle: String, value: String, identifier: String? = nil, action: @escaping () -> Void) -> some View {
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                DropdownButton(text: value, mode: .transparent, action: action)
                    .withIdentifier(identifier)
            }
        )
    }
}
