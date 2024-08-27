import SwiftUI
import DatePicker
import class DatePicker.DatePicker
import protocol DatePicker.DatePickerDelegate
import protocol DatePicker.DatePickerDataSource

struct DatePickerUIViewRepresentable: UIViewRepresentable {
    @Binding private var dateRange: ClosedRange<Date>?
    @Binding private var isEnabled: Bool
    @Binding private var layoutDirection: DatePickerDateModeSettings.LayoutDirection
    @Binding private var highlightsCurrentDate: Bool
    @Binding private var currentDateSelection: DatePickerDateModeSettings.CurrentDateSelection
    @Binding private var limitAvailableDates: Bool
    @Binding private var disableSomeDates: Bool
    @Binding private var annotation: String

    init(dateRange: Binding<ClosedRange<Date>?>,
         isEnabled: Binding<Bool>,
         layoutDirection: Binding<DatePickerDateModeSettings.LayoutDirection>,
         highlightsCurrentDate: Binding<Bool>,
         currentDateSelection: Binding<DatePickerDateModeSettings.CurrentDateSelection>,
         limitAvailableDates: Binding<Bool>,
         disableSomeDates: Binding<Bool>,
         annotation: Binding<String>) {

        _dateRange = dateRange
        _isEnabled = isEnabled
        _layoutDirection = layoutDirection
        _highlightsCurrentDate = highlightsCurrentDate
        _currentDateSelection = currentDateSelection
        _limitAvailableDates = limitAvailableDates
        _disableSomeDates = disableSomeDates
        _annotation = annotation
    }

    func makeUIView(context: Context) -> DatePicker {
        let datePicker = DatePicker()
        datePicker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        datePicker.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        datePicker.addAction(UIAction { _ in
            dateRange = datePicker.dateRange
        }, for: .valueChanged)

        datePicker.delegate = context.coordinator
        datePicker.dataSource = context.coordinator

        return datePicker
    }

    func updateUIView(_ uiView: DatePicker, context: Context) {
        let calendar = Calendar.current
        let minimumDate = Date().addingTimeInterval(-86400 * 3)

        uiView.isEnabled = isEnabled

        uiView.minimumDate = limitAvailableDates
            ? calendar.startOfDay(for: minimumDate)
            : nil

        uiView.mode = .date(.init(
            layoutDirection: layoutDirection,
            selectionBehavior: .range,
            highlightsCurrentDate: highlightsCurrentDate,
            currentDateSelection: currentDateSelection
        ))

        uiView.reloadAllDates()
    }

    func makeCoordinator() -> DatePickerUIViewRepresentable.Coordinator {
        return DatePickerUIViewRepresentable.Coordinator(
            annotation: $annotation,
            disableSomeDates: $disableSomeDates
        )
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, DatePickerDelegate, DatePickerDataSource {
        private let disabledRange = (-9 ... -3).dateRange(relativeTo: Date())
        private let annotatedRange = (-3 ... 3).dateRange(relativeTo: Date())
        private let interactiveRange = (-4 ... -1).dateRange(relativeTo: Date())

        let annotation: Binding<String>
        let disableSomeDates: Binding<Bool>

        init(annotation: Binding<String>,
             disableSomeDates: Binding<Bool>) {

            self.annotation = annotation
            self.disableSomeDates = disableSomeDates
        }

        // MARK: - DatePickerDelegate

        func datePicker(_ datePicker: DatePicker, canSelectDate date: Date) -> Bool {
            guard disableSomeDates.wrappedValue else { return true }
            return !disabledRange.contains(date)
        }

        func datePicker(_ datePicker: DatePicker,
                        canSelectDate date: Date,
                        inRange range: ClosedRange<Date>) -> Bool {

            return !interactiveRange.contains(date)
        }

        func datePicker(_ datePicker: DatePicker,
                        didTapDate date: Date,
                        inRange range: ClosedRange<Date>) {

            guard range == interactiveRange else { return }

            let alert = UIAlertController(
                title: nil,
                message: "Interactive range tapped",
                preferredStyle: .alert
            )

            alert.addAction(.init(title: "OK", style: .cancel))

            // Ugly but just for demo
            let vc = UIApplication.shared.keyWindow?.rootViewController
            vc?.present(alert, animated: true)
        }

        // MARK: - DatePickerDataSource

        func datePicker(_ datePicker: DatePicker, annotationForDate date: Date) -> String? {
            guard !annotation.wrappedValue.isEmpty,
                  annotatedRange.contains(day: date)
            else {
                return nil
            }

            return annotation.wrappedValue
        }

        func datePicker(_ datePicker: DatePicker, rangeContainingDate date: Date) -> ClosedRange<Date>? {
            if interactiveRange.contains(date) {
                return interactiveRange
            } else {
                return nil
            }
        }

        func datePicker(_ datePicker: DatePicker,
                        backgroundColorForDate date: Date,
                        inRange range: ClosedRange<Date>) -> UIColor {

            return .dynamic(
                light: .systemPurple.withAlphaComponent(0.3),
                dark: .systemPurple.withAlphaComponent(0.6)
            )
        }

        func datePicker(_ datePicker: DatePicker, textColorForDate date: Date) -> UIColor? {
            return Calendar.current.isDateInWeekend(date)
                ? .systemRed
                : nil
        }
    }
}

// MARK: - Extensions

private extension ClosedRange where Bound == Date {
    func contains(day date: Date) -> Bool {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: date)
        let from = calendar.startOfDay(for: lowerBound)
        let to = calendar.startOfDay(for: upperBound)
        return (from ... to).contains(date)
    }
}

private extension ClosedRange where Bound == Int {
    func dateRange(relativeTo date: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let date = calendar.startOfDay(for: date)
        let from = calendar.date(byAdding: .day, value: lowerBound, to: date) ?? date
        let to = calendar.date(byAdding: .day, value: upperBound, to: date) ?? date
        return from ... to
    }
}

private extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }
}
