import Foundation

public protocol DatePickerDelegate: AnyObject {
    /// Is the date `date` available for selection
    /// - Returns: default is `true`
    func datePicker(_ datePicker: DatePicker, canSelectDate date: Date) -> Bool

    /// Notifies about tapping on the date `date` in the range `range`
    func datePicker(_ datePicker: DatePicker,
                    didTapDate date: Date,
                    inRange range: ClosedRange<Date>)

    /// Is it possible to select the date `date` in the range `range`
    /// If possible, the date in the range is considered non–interactive, and the component
    /// will NOT notify about tapping on the date `date` using the delegate method `didTapDate:inRange:`
    /// - Returns: default is `false`
    func datePicker(_ datePicker: DatePicker,
                    canSelectDate date: Date,
                    inRange range: ClosedRange<Date>) -> Bool
}

public extension DatePickerDelegate {
    func datePicker(_ datePicker: DatePicker, canSelectDate date: Date) -> Bool { true }
    func datePicker(_ datePicker: DatePicker,
                    didTapDate date: Date,
                    inRange range: ClosedRange<Date>) {}
    func datePicker(_ datePicker: DatePicker,
                    canSelectDate date: Date,
                    inRange range: ClosedRange<Date>) -> Bool { false }
}
