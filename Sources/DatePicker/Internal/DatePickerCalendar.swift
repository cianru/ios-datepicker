import Foundation

/// System calendar helper
final class DatePickerCalendar {
    /// Reference component initialization date
    let referenceDate: Date
    let referenceDateRange: ClosedRange<Date>

    private lazy var yearFormatter = makeDateFormatter(format: "y")
    private lazy var monthFormatter = makeDateFormatter(format: "LLLL")
    private lazy var monthAndYearFormatter = makeDateFormatter(format: "LLLL y")

    private lazy var accessibilityDateFormatter: DateFormatter = {
        let dateFormatter = makeDateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()

    private let calendar: Calendar

    init(calendar: Calendar) {
        referenceDate = Date()
        referenceDateRange = referenceDate ... referenceDate

        self.calendar = calendar
    }

    // MARK: - Formatting

    var monthNames: [String] { calendar.standaloneMonthSymbols.map(\.capitalized) }

    var weekdayNames: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols

        return (0..<symbols.count).compactMap {
            let weekday = ($0 + calendar.firstWeekday - 1) % symbols.count
            return symbols[safe: weekday]?.uppercased()
        }
    }

    func yearString(for date: Date) -> String {
        return yearFormatter.string(from: date)
    }

    func monthString(for date: Date) -> String {
        return monthFormatter.string(from: date).capitalized
    }

    func dayString(for date: Date) -> String {
        // Called for every cell and must be fast
        return "\(day(for: date))"
    }

    func monthAndYearString(for date: Date) -> String {
        return monthAndYearFormatter.string(from: date).capitalized
    }

    func accessibilityString(for date: Date) -> String {
        return accessibilityDateFormatter.string(from: date)
    }

    // MARK: - Ranges

    func contains(month date: Date, in months: ClosedRange<Date>) -> Bool {
        let date = startOfMonth(for: date)
        let from = startOfMonth(for: months.lowerBound)
        let to = startOfMonth(for: months.upperBound)
        return (from ... to).contains(date)
    }

    func contains(day date: Date, in days: ClosedRange<Date>) -> Bool {
        let date = startOfDay(for: date)
        let from = startOfDay(for: days.lowerBound)
        let to = startOfDay(for: days.upperBound)
        return (from ... to).contains(date)
    }

    // MARK: - Clamping

    func clamp(month date: Date, to months: ClosedRange<Date>) -> Date {
        let date = startOfMonth(for: date)
        let from = startOfMonth(for: months.lowerBound)
        let to = startOfMonth(for: months.upperBound)
        return min(max(date, from), to)
    }

    func clamp(day date: Date, to days: ClosedRange<Date>) -> Date {
        let date = startOfDay(for: date)
        let from = startOfDay(for: days.lowerBound)
        let to = startOfDay(for: days.upperBound)
        return min(max(date, from), to)
    }

    // MARK: - Addition & subtraction

    func dateByAdding(years: Int, to date: Date) -> Date {
        return calendar.date(byAdding: .year, value: years, to: date) ?? date
    }

    func dateByAdding(months: Int, to date: Date) -> Date {
        return calendar.date(byAdding: .month, value: months, to: date) ?? date
    }

    func dateByAdding(days: Int, to date: Date) -> Date {
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    func nextMonth(for date: Date) -> Date {
        return dateByAdding(months: 1, to: date)
    }

    func previousMonth(for date: Date) -> Date {
        return dateByAdding(months: -1, to: date)
    }

    func nextDay(for date: Date) -> Date {
        return dateByAdding(days: 1, to: date)
    }

    // MARK: - Counting

    func numberOfYears(from: Date, to: Date) -> Int {
        let from = startOfYear(for: from)
        let to = startOfYear(for: to)
        return calendar.dateComponents([.year], from: from, to: to).year ?? 0
    }

    func numberOfMonths(from: Date, to: Date) -> Int {
        let from = startOfMonth(for: from)
        let to = startOfMonth(for: to)
        return calendar.dateComponents([.month], from: from, to: to).month ?? 0
    }

    func numberOfDays(in date: Date) -> Int {
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 0
    }

    // MARK: - Starting dates

    func startOfYear(for date: Date) -> Date {
        return calendar.date(from: calendar.dateComponents(
            [.year],
            from: date
        )) ?? date
    }

    func startOfMonth(for date: Date) -> Date {
        return calendar.date(from: calendar.dateComponents(
            [.year, .month],
            from: date
        )) ?? date
    }

    func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }

    // MARK: - Comparison & equality

    func haveSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        return calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    func haveSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        return calendar.isDate(lhs, equalTo: rhs, toGranularity: .day)
    }

    func haveSameDays(_ lhs: ClosedRange<Date>?, _ rhs: ClosedRange<Date>?) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.some(let lhsRange), .some(let rhsRange)):
            return haveSameDay(lhsRange.lowerBound, rhsRange.lowerBound)
                && haveSameDay(lhsRange.upperBound, rhsRange.upperBound)
        default:
            return false
        }
    }

    // MARK: - Components

    func weekday(for date: Date) -> Int {
        return calendar.component(.weekday, from: date) - calendar.firstWeekday
    }

    func month(for date: Date) -> Int {
        return calendar.component(.month, from: date)
    }

    func day(for date: Date) -> Int {
        return calendar.component(.day, from: date)
    }

    // MARK: - Combine

    func combine(date: Date, time: Date) -> Date? {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        return calendar.date(from: .init(
            calendar: calendar,
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute,
            second: timeComponents.second
        ))
    }

    func combine(day: Date, month: Date) -> Date? {
        let dayAndTimeComponents = calendar.dateComponents([.day, .hour, .minute, .second], from: day)
        let monthAndYearComponents = calendar.dateComponents([.year, .month], from: month)
        let numberOfDays = numberOfDays(in: month)

        return calendar.date(from: .init(
            calendar: calendar,
            year: monthAndYearComponents.year,
            month: monthAndYearComponents.month,
            day: dayAndTimeComponents.day.map { min($0, numberOfDays) },
            hour: dayAndTimeComponents.hour,
            minute: dayAndTimeComponents.minute,
            second: dayAndTimeComponents.second
        ))
    }

    func combine(days: ClosedRange<Date>, month: Date) -> ClosedRange<Date>? {
        guard let toDay = combine(day: days.upperBound, month: month) else {
            return nil
        }

        // When moving date range to a new month or year,
        // upper bound of the range is the reference date,
        // and the lower bound is calculated depending on this reference date
        let numberOfMonths = numberOfMonths(from: days.lowerBound, to: days.upperBound)
        let fromMonth = dateByAdding(months: -numberOfMonths, to: toDay)
        guard let fromDay = combine(day: days.lowerBound, month: fromMonth) else {
            return nil
        }

        guard fromDay <= toDay else {
            return nil
        }

        return fromDay ... toDay
    }

    // MARK: - Enumerate

    func enumerate(days: ClosedRange<Date>, _ block: (Date) -> Bool) {
        var date = days.lowerBound
        while date <= days.upperBound && block(date) {
            date = nextDay(for: date)
        }
    }
}

// MARK: - Internal

private extension DatePickerCalendar {
    func makeDateFormatter(format: String? = nil) -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = calendar.locale
        format.map { dateFormatter.dateFormat = $0 }
        return dateFormatter
    }
}
