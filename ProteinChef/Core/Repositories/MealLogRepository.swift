import Foundation

protocol MealLogRepositoryProtocol: Sendable {
    func list(ownerUid: String, on day: Date) async throws -> [MealLog]
    func listStream(ownerUid: String, on day: Date) -> AsyncThrowingStream<[MealLog], Error>
    func save(_ log: MealLog) async throws
    func delete(ownerUid: String, id: String) async throws
}

enum MealLogDate {
    /// Normalizes any Date to noon local time for that calendar day, which is how we store
    /// MealLog.date in Firestore. This avoids timezone edge cases around midnight.
    static func normalizeToNoon(_ day: Date, calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? day
    }

    /// Start (inclusive) and end (exclusive) of the local day containing `day`.
    static func dayBounds(_ day: Date, calendar: Calendar = .current) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }
}
