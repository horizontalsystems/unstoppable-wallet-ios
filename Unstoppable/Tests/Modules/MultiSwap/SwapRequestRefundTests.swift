import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

struct SwapRequestRefundTests {
    @Test func actionRequiredStatusIsPending() {
        #expect(Swap.Status(rawValue: "action_required") == .actionRequired)
        #expect(Swap.pendingStatuses.contains(.actionRequired))
    }

    @Test func trackResponseDecodesActionRequiredAndPauseReason() throws {
        let response = try Mapper<USwapMultiSwapProvider.TrackResponse>().map(JSON: [
            "status": "action_required",
            "fromAsset": "btc",
            "toAsset": "eth",
            "toAmount": "1.23",
            "meta": [
                "provider": "PEGASUS",
                "pauseReason": "aml",
            ],
            "legs": [
                [
                    "status": "completed",
                    "type": "native_send",
                    "chainId": "bitcoin",
                    "hash": "deposit-hash",
                    "fromAsset": "btc",
                    "toAsset": "btc",
                ],
            ],
        ])

        #expect(response.status == .actionRequired)
        #expect(response.provider == "PEGASUS")
        #expect(response.pauseReason == "aml")
    }

    @Test func unknownTrackStatusDecodesAsUnknown() throws {
        let response = try Mapper<USwapMultiSwapProvider.TrackResponse>().map(JSON: [
            "status": "new_provider_status",
            "fromAsset": "btc",
            "toAsset": "eth",
            "legs": [],
        ])

        #expect(response.status == .unknown)
    }

    @Test func providerContactsParseFromProvidersResponse() throws {
        let response = try Mapper<SwapProviderInfoManager.ProviderResponse>().map(JSON: [
            "provider": "Exolix",
            "contacts": [
                "email": "support@example.com",
                "telegram": "https://t.me/example",
                "twitter": "https://x.com/example",
                "website": "https://example.com",
            ],
        ])

        #expect(response.provider == "Exolix")
        #expect(response.contacts?.email == "support@example.com")
        #expect(response.contacts?.telegram == "https://t.me/example")
        #expect(response.contacts?.twitter == "https://x.com/example")
        #expect(response.contacts?.website == "https://example.com")
    }

    @Test func emailBodyMatchesAndroidShape() {
        let body = SwapRequestRefundBuilder.emailBody(
            swapId: "swap-1",
            fromAsset: "BTC",
            toAsset: "ETH",
            amount: "0.1 BTC",
            txHash: "hash-1"
        )

        #expect(body.contains("My swap was stopped after the deposit was received. I would like to request a refund."))
        #expect(body.contains("Swap ID: swap-1"))
        #expect(body.contains("From: BTC"))
        #expect(body.contains("To: ETH"))
        #expect(body.contains("Amount: 0.1 BTC"))
        #expect(body.contains("Deposit transaction: hash-1"))
    }

    @Test func contactURLValidationRejectsUnsafeValues() {
        let telegram = SwapRequestRefundBuilder.ContactLink(type: .telegram, label: "Telegram", value: "", rawValue: "https://t.me/provider", icon: "")
        let telegramHandle = SwapRequestRefundBuilder.ContactLink(type: .telegram, label: "Telegram", value: "", rawValue: "@QuickExSupport", icon: "")
        let telegramHostWithoutScheme = SwapRequestRefundBuilder.ContactLink(type: .telegram, label: "Telegram", value: "", rawValue: "t.me/provider", icon: "")
        let twitter = SwapRequestRefundBuilder.ContactLink(type: .twitter, label: "Twitter", value: "", rawValue: "https://x.com/provider", icon: "")
        let website = SwapRequestRefundBuilder.ContactLink(type: .website, label: "Website", value: "", rawValue: "https://provider.example", icon: "")
        let javascript = SwapRequestRefundBuilder.ContactLink(type: .website, label: "Website", value: "", rawValue: "javascript:alert(1)", icon: "")
        let wrongTelegram = SwapRequestRefundBuilder.ContactLink(type: .telegram, label: "Telegram", value: "", rawValue: "https://evil.example/provider", icon: "")
        let customScheme = SwapRequestRefundBuilder.ContactLink(type: .twitter, label: "Twitter", value: "", rawValue: "twitter://user?id=1", icon: "")

        #expect(SwapRequestRefundBuilder.safeURL(contactLink: telegram) != nil)
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: telegramHandle)?.absoluteString == "https://t.me/QuickExSupport")
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: telegramHostWithoutScheme)?.absoluteString == "https://t.me/provider")
        #expect(SwapRequestRefundBuilder.telegramURLs(contactLink: telegram)?.appURL?.absoluteString == "tg://resolve?domain=provider")
        #expect(SwapRequestRefundBuilder.telegramURLs(contactLink: telegramHandle)?.appURL?.absoluteString == "tg://resolve?domain=QuickExSupport")
        #expect(SwapRequestRefundBuilder.telegramURLs(contactLink: telegramHostWithoutScheme)?.appURL?.absoluteString == "tg://resolve?domain=provider")
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: twitter) != nil)
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: website) != nil)
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: javascript) == nil)
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: wrongTelegram) == nil)
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: customScheme) == nil)
    }

    @Test func providerEmailURLFallsBackToWebsiteContact() throws {
        let contacts = SwapProviderInfoManager.Contacts(
            email: "https://www.pegasusswap.com",
            telegram: nil,
            twitter: nil,
            website: nil
        )

        let links = SwapRequestRefundBuilder.contactLinks(contacts: contacts)
        let link = try #require(links.first)

        #expect(links.count == 1)
        #expect(link.type == .website)
        #expect(link.rawValue == "https://www.pegasusswap.com")
        #expect(SwapRequestRefundBuilder.safeURL(contactLink: link) != nil)
        #expect(SwapRequestRefundBuilder.mailtoURL(email: link.rawValue, subject: "Subject", body: "Body") == nil)
    }

    @Test func providerValidEmailRemainsEmailContact() throws {
        let contacts = SwapProviderInfoManager.Contacts(
            email: "Support@letsexchange.io",
            telegram: nil,
            twitter: nil,
            website: nil
        )

        let links = SwapRequestRefundBuilder.contactLinks(contacts: contacts)
        let link = try #require(links.first)

        #expect(links.count == 1)
        #expect(link.type == .email)
        #expect(link.rawValue == "Support@letsexchange.io")
        #expect(SwapRequestRefundBuilder.mailtoURL(email: link.rawValue, subject: "Subject", body: "Body") != nil)
    }

    @Test func mailtoFallbackEncodesAdversarialBody() throws {
        let url = try #require(SwapRequestRefundBuilder.mailtoURL(
            email: "support@example.com",
            subject: "Refund Request - swap&bcc=attacker@example.com",
            body: "Line 1\r\nbcc: attacker@example.com"
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []
        let queryItemNames = queryItems.map(\.name)

        #expect(components.scheme == "mailto")
        #expect(components.path == "support@example.com")
        #expect(queryItemNames == ["subject", "body"])
        #expect(!queryItemNames.contains("bcc"))
        #expect(!url.absoluteString.contains("\r"))
        #expect(!url.absoluteString.contains("\n"))
    }
}
