import UIKit

public protocol DatePickerProtocol: UIView {
    /// Date picker mode
    /// - `.date` – calendar to select date
    /// - `.time` – wheel to select time
    /// Default is `.date`
    var mode: DatePickerMode { get set }

    /// Minimum date available for selection (including)
    /// If `nil`, then there is no limit
    /// If the value is greater than `maximumDate`, both parameters are ignored
    /// Default is `nil`
    var minimumDate: Date? { get set }

    /// Maximum date available for selection (including)
    /// If `nil`, then there is no limit
    /// If the value is less than `minimumDate`, both parameters are ignored
    /// Default is `nil`
    var maximumDate: Date? { get set }

    /// Range of selected dates
    /// If only one is selected, both bounds of the range are equal to the selected date (`date`)
    /// If it is not equal to `nil`, the calendar is initialized on the month of the last date of the range,
    /// otherwise on the month of the current date
    /// Default is `nil`
    var dateRange: ClosedRange<Date>? { get set }

    /// Selected date
    /// If a range is selected, it is equal to the first date of this range (`dateRange.lowerBound`)
    /// Default is the current date
    ///
    /// NOTE: The property is not optional for compatibility with `UIDatePicker`,
    /// if you need optionality, use `dateRange`
    var date: Date { get set }

    var delegate: DatePickerDelegate? { get set }
    var dataSource: DatePickerDataSource? { get set }

    /// Date range selection
    /// - Parameters:
    ///   - dateRange: new date range, `nil` removes the selection
    ///   - animated: selection with animation
    func setDateRange(_ dateRange: ClosedRange<Date>?, animated: Bool)

    /// Date selection
    /// - Parameters:
    ///   - date: new date, `nil` removes the selection
    ///   - animated: selection with animation
    func setDate(_ date: Date?, animated: Bool)

    /// Reload information for all visible dates
    /// using the delegate and the data source
    func reloadAllDates()
}

/// Date picker mode
public enum DatePickerMode: Equatable {
    /// Calendar to select date
    case date(DatePickerDateModeSettings = .init())
    /// Wheel to select time
    case time(DatePickerTimeModeSettings = .init())

    /// Calendar to select date
    public static let date = DatePickerMode.date()

    /// Wheel to select time
    public static let time = DatePickerMode.time()
}

/// Date selection mode settings
public struct DatePickerDateModeSettings: Equatable {
    /// Calendar layout direction
    public enum LayoutDirection: Equatable {
        /// Horizontal layout
        /// Used when the component is part of a form,
        /// or does not take up most of the screen
        case horizontal

        /// Vertical layout
        /// Used when the component is the main one on the screen,
        /// and takes up most of its space
        case vertical
    }

    /// Date selection behavior
    public enum SelectionBehavior: Equatable {
        /// Single date selection
        case single
        /// Date range selection
        case range(clampingBehavior: RangeClampingBehavior)

        public static let range = SelectionBehavior.range(clampingBehavior: .untilFirstDisabled)
    }

    /// Date range clamping behavior
    public enum RangeClampingBehavior: Equatable {
        /// Do not clamp the selected range
        case off
        /// Clamp the selected range to the first available date
        case untilFirstDisabled
    }

    /// Automatic selection of the current date
    /// when initializing the calendar
    public enum CurrentDateSelection: Equatable {
        /// Select the current date
        case on
        /// Do not select the current date
        case off
        /// Automatic:
        /// - `.on` for `selectionBehavior == .single`
        /// - `.off` for `selectionBehavior == .range`
        case automatic
    }

    /// Calendar layout direction
    /// - `.horizontal` – horizontal
    /// - `.vertical` – vertical
    public let layoutDirection: LayoutDirection

    /// Date selection behavior
    /// - `.single` – single date selection
    /// - `.range` – date range selection
    /// Default is `.single`
    public let selectionBehavior: SelectionBehavior

    /// Highlights current date
    /// Default is `true`
    public let highlightsCurrentDate: Bool

    /// Automatic selection of the current date
    /// when initializing the calendar
    /// - `.on` – select the current date
    /// - `.off` – do not select the current date
    /// - `.automatic` – select or not depending on `selectionBehavior`
    /// Default is `.automatic`
    public let currentDateSelection: CurrentDateSelection

    public init(layoutDirection: LayoutDirection = .horizontal,
                selectionBehavior: SelectionBehavior = .single,
                highlightsCurrentDate: Bool = true,
                currentDateSelection: CurrentDateSelection = .automatic) {

        self.layoutDirection = layoutDirection
        self.selectionBehavior = selectionBehavior
        self.highlightsCurrentDate = highlightsCurrentDate
        self.currentDateSelection = currentDateSelection
    }
}

/// Time selection mode
public struct DatePickerTimeModeSettings: Equatable {
    /// Interval on the minute wheel
    /// Value must be a divisor of `60`
    /// Minimum value is `1`, maximum is `30`
    /// Default is `1`
    public let minuteInterval: Int

    public init(minuteInterval: Int = 1) {
        self.minuteInterval = minuteInterval
    }
}
