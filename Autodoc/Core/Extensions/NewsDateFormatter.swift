import Foundation

enum NewsDateFormatter {
    private static let locale = Locale(identifier: "ru_RU")

    static func string(from date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) {
            return String(localized: "Сегодня")
        }

        if calendar.isDateInYesterday(date) {
            return String(localized: "Вчера")
        }

        let isSameYear = calendar.isDate(date, equalTo: now, toGranularity: .year)
        return date.formatted(style(includingYear: !isSameYear).locale(locale))
    }

    private static func style(includingYear: Bool) -> Date.FormatStyle {
        includingYear
            ? .dateTime.day().month(.wide).year()
            : .dateTime.day().month(.wide)
    }
}
