class EmojiHelper: IEmojiHelper {
    private static let rocket = "🚀"
    private static let moon = "🌙"
    private static let brokenHeart = "💔"
    private static let multiAlerts = "📉📈"
    private static let positive5 = "😎"
    private static let positive3 = "😉"
    private static let positive2 = "🙂"
    private static let negative5 = "😩"
    private static let negative3 = "😧"
    private static let negative2 = "😔"

    let multiAlerts: String = EmojiHelper.multiAlerts

    func title(forState state: Int) -> String {
        var emoji = state > 0 ? EmojiHelper.rocket : EmojiHelper.brokenHeart
        if state >= 5 {
            emoji += EmojiHelper.moon
        }
        return emoji
    }

    func body(forState state: Int) -> String {
        switch state {
        case -5: return EmojiHelper.negative5
        case -3: return EmojiHelper.negative3
        case -2: return EmojiHelper.negative2
        case 2: return EmojiHelper.positive2
        case 3: return EmojiHelper.positive3
        case 5: return EmojiHelper.positive5
        default: return ""
        }
    }

}
