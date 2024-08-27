import UIKit

protocol DatePickerMonthPickerDelegate: AnyObject {
    func didChangeSelectedDate(in monthPicker: DatePickerMonthPicker)
}

/// Custom month and year selection wheel, since the standard `UIDatePicker`
/// does not support date selection *without* days
///
/// Implementation has several differences from a similar wheel in the `UIDatePicker`:
/// - number of available years is limited by the `availableDates` range
/// - missing dimming of the months that are not available for selection
final class DatePickerMonthPicker: UIView {
    private enum Constants {
        // Number of months in the wheel to create
        // the illusion of "endless" wheel
        static let totalNumberOfMonths = numberOfMonthsInYear * 10
        static let numberOfMonthsInYear = 12
    }

    private enum Component: Int, CaseIterable {
        case month
        case year
    }

    weak var delegate: DatePickerMonthPickerDelegate?

    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            updateEnabledState()
        }
    }

    var availableDates: ClosedRange<Date> = .distantPast ... .distantFuture {
        didSet {
            guard availableDates != oldValue else { return }
            updateAvailableDates()
            updateSelectedDate()
        }
    }

    private(set) var selectedDate = Date.distantPast

    private lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        return pickerView
    }()

    private let settings: DatePickerSettings
    private let calendar: DatePickerCalendar

    init(settings: DatePickerSettings, calendar: DatePickerCalendar) {
        self.settings = settings
        self.calendar = calendar
        super.init(frame: .zero)

        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pickerView.frame = bounds
    }

    func setSelectedDate(_ date: Date, animated: Bool) {
        let date = calendar.clamp(month: date, to: availableDates)
        let rows = rows(from: date)

        pickerView.selectRow(rows.month, inComponent: Component.month.rawValue, animated: animated)
        pickerView.selectRow(rows.year, inComponent: Component.year.rawValue, animated: animated)

        selectedDate = date
    }
}

// MARK: - UIPickerViewDataSource

extension DatePickerMonthPicker: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return Component.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch Component(rawValue: component) {
        case .month:
            return Constants.totalNumberOfMonths
        case .year:
            return calendar.numberOfYears(
                from: availableDates.lowerBound,
                to: availableDates.upperBound
            ) + 1
        default:
            return 0
        }
    }
}

// MARK: - UIPickerViewDelegate

extension DatePickerMonthPicker: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {

        switch Component(rawValue: component) {
        case .month:
            return calendar.monthNames[safe: month(for: row)]
        case .year:
            let date = calendar.dateByAdding(
                years: row,
                to: calendar.startOfYear(for: availableDates.lowerBound)
            )

            return calendar.yearString(for: date)
        default:
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {

        let month = pickerView.selectedRow(inComponent: Component.month.rawValue)
        let year = pickerView.selectedRow(inComponent: Component.year.rawValue)
        let date = date(from: .init(year: year, month: month))
        let oldSelectedDate = selectedDate

        if calendar.contains(month: date, in: availableDates) {
            selectedDate = date
        } else {
            // Selected month is outside the available dates range,
            // so reset to the nearest one in the range
            setSelectedDate(date, animated: true)
        }

        notifyDidChangeSelectedDateIfNeeded(oldDate: oldSelectedDate)
    }
}

// MARK: - UIPickerViewAccessibilityDelegate

extension DatePickerMonthPicker: UIPickerViewAccessibilityDelegate {
    func pickerView(_ pickerView: UIPickerView, accessibilityLabelForComponent component: Int) -> String? {
        switch Component(rawValue: component) {
        case .month:
            return settings.accessibility.labels.month
        case .year:
            return settings.accessibility.labels.year
        default:
            return nil
        }
    }
}

// MARK: - Layout

private extension DatePickerMonthPicker {
    func setupLayout() {
        addSubview(pickerView)
    }
}

// MARK: - Internal

private extension DatePickerMonthPicker {
    struct Rows {
        let year: Int
        let month: Int
    }

    func updateAvailableDates() {
        // Reload only years, since number of months is static
        pickerView.reloadComponent(Component.year.rawValue)
    }

    func updateSelectedDate() {
        setSelectedDate(selectedDate, animated: false)
    }

    func updateEnabledState() {
        if isEnabled {
            pickerView.isUserInteractionEnabled = true
            pickerView.alpha = 1
        } else {
            pickerView.isUserInteractionEnabled = false
            // Native UIDatePicker alpha when isEnabled == false
            pickerView.alpha = 0.4
        }
    }

    func notifyDidChangeSelectedDateIfNeeded(oldDate: Date) {
        guard !calendar.haveSameMonth(selectedDate, oldDate) else { return }
        delegate?.didChangeSelectedDate(in: self)
    }

    func date(from rows: Rows) -> Date {
        let yearDate = calendar.dateByAdding(
            years: rows.year,
            to: calendar.startOfYear(for: availableDates.lowerBound)
        )

        return calendar.dateByAdding(months: month(for: rows.month), to: yearDate)
    }

    func rows(from date: Date) -> Rows {
        let year = calendar.numberOfYears(from: availableDates.lowerBound, to: date)
        let month = row(for: calendar.month(for: date) - 1)
        return .init(year: year, month: month)
    }

    func month(for row: Int) -> Int {
        return row % Constants.numberOfMonthsInYear
    }

    func row(for month: Int) -> Int {
        // Months starts from the middle of the wheel
        return (Constants.totalNumberOfMonths / 2)
            / Constants.numberOfMonthsInYear
            * Constants.numberOfMonthsInYear
            + month
    }
}
