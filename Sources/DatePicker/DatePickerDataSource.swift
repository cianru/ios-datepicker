import UIKit

public protocol DatePickerDataSource: AnyObject {
    /// Annotation text under the date `date`
    /// - Returns: `nil` if annotation should not be shown, the default is `nil`
    func datePicker(_ datePicker: DatePicker, annotationForDate date: Date) -> String?

    /// Range containing the date `date`
    /// - Returns: default is `nil`
    func datePicker(_ datePicker: DatePicker, rangeContainingDate date: Date) -> ClosedRange<Date>?

    /// Background color for the date `date` in the range `range`
    /// - Returns: default is `.clear`
    func datePicker(_ datePicker: DatePicker,
                    backgroundColorForDate date: Date,
                    inRange range: ClosedRange<Date>) -> UIColor

    /// Text color for the  date `date`
    /// - Returns: default is `nil`
    func datePicker(_ datePicker: DatePicker, textColorForDate date: Date) -> UIColor?
}

public extension DatePickerDataSource {
    func datePicker(_ datePicker: DatePicker, annotationForDate date: Date) -> String? { nil }
    func datePicker(_ datePicker: DatePicker, rangeContainingDate date: Date) -> ClosedRange<Date>? { nil }
    func datePicker(_ datePicker: DatePicker,
                    backgroundColorForDate date: Date,
                    inRange range: ClosedRange<Date>) -> UIColor { .clear }
    func datePicker(_ datePicker: DatePicker, textColorForDate date: Date) -> UIColor? { nil }
}
