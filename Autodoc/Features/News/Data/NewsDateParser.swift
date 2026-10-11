import Foundation

nonisolated enum NewsDateParser {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow") ?? .gmt
        return calendar
    }()

    static func date(from string: String) -> Date? {
        let numbers = string
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }

        guard numbers.count >= 3 else {
            return nil
        }

        return calendar.date(from: components(from: numbers))
    }

    private static func components(from numbers: [Int]) -> DateComponents {
        DateComponents(
            year: numbers[0],
            month: numbers[1],
            day: numbers[2],
            hour: numbers.count > 3 ? numbers[3] : 0,
            minute: numbers.count > 4 ? numbers[4] : 0,
            second: numbers.count > 5 ? numbers[5] : 0
        )
    }
}
