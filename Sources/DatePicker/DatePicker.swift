import UIKit

public final class DatePicker: UIControl,
                               DatePickerProtocol {

    public var mode: DatePickerMode = .date {
        didSet {
            guard mode != oldValue else { return }
            updateMode(oldMode: oldValue)
            updateHeaderVisibility()
            updateAvailableDates()
            updateDateRange()
            updateEnabledState()
            updateAccessibility()
        }
    }

    public var minimumDate: Date? {
        didSet {
            guard minimumDate != oldValue else { return }
            updateAvailableDates()
        }
    }

    public var maximumDate: Date? {
        didSet {
            guard maximumDate != oldValue else { return }
            updateAvailableDates()
        }
    }

    public var dateRange: ClosedRange<Date>? {
        get {
            switch mode {
            case .date:
                return calendarView.selectedDates
            case .time:
                return timePicker.date ... timePicker.date
            }
        }
        set {
            setDateRange(newValue, animated: false)
        }
    }

    public var date: Date {
        get { dateRange?.lowerBound ?? calendar.referenceDate }
        set { dateRange = newValue ... newValue }
    }

    public weak var delegate: DatePickerDelegate?
    public weak var dataSource: DatePickerDataSource?

    private lazy var calendar = DatePickerCalendar(calendar: systemCalendar)

    private lazy var headerView: DatePickerHeaderView = {
        let headerView = DatePickerHeaderView(settings: settings)
        headerView.delegate = self
        return headerView
    }()

    private lazy var calendarView: DatePickerCalendarView = {
        let calendarView = DatePickerCalendarView(settings: settings, calendar: calendar)
        calendarView.delegate = self
        calendarView.dataSource = self
        return calendarView
    }()

    private lazy var monthPicker: DatePickerMonthPicker = {
        let monthPicker = DatePickerMonthPicker(settings: settings, calendar: calendar)
        monthPicker.delegate = self
        monthPicker.alpha = 0
        return monthPicker
    }()

    // It is highly discouraged to access the property outside of the .time mode,
    // because initialization of the UIDatePicker is quite heavy
    private lazy var timePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.calendar = systemCalendar
        datePicker.locale = systemCalendar.locale
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels

        datePicker.addAction(for: .valueChanged) { [weak self] in
            guard let self else { return }
            sendActions(for: .valueChanged)
        }

        return datePicker
    }()

    private let settings: DatePickerSettings
    private let systemCalendar: Calendar

    public init(settings: DatePickerSettings = .default,
                calendar: Calendar = .current) {

        self.settings = settings
        self.systemCalendar = calendar
        super.init(frame: .zero)

        setupLayout()

        updateMode(oldMode: mode)
        updateHeaderVisibility()
        updateAvailableDates()
        updateEnabledState()
        updateAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            updateEnabledState()
        }
    }

    public override var intrinsicContentSize: CGSize {
        return sizeThatFits(UIView.layoutFittingExpandedSize)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutPickers()
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        switch mode {
        case .date:
            let headerSize = headerView.isHidden
                ? .zero
                : headerView.sizeThatFits(size)
            let calendarSize = calendarView.sizeThatFits(size)

            return .init(
                width: calendarSize.width,
                height: headerSize.height + calendarSize.height
            )
        case .time:
            return timePicker.sizeThatFits(size)
        }
    }

    public func setDateRange(_ dateRange: ClosedRange<Date>?, animated: Bool) {
        switch mode {
        case .date:
            calendarView.setSelectedDates(dateRange)

            if let date = calendarView.selectedDates?.upperBound {
                setVisibleDate(date, animated: animated)
            }
        case .time:
            if let date = dateRange?.upperBound {
                timePicker.setDate(date, animated: animated)
            }
        }
    }

    public func setDate(_ date: Date?, animated: Bool) {
        setDateRange(date.map { $0 ... $0 }, animated: animated)
    }

    public func reloadAllDates() {
        switch mode {
        case .date:
            calendarView.reloadAllDates()
        case .time:
            break
        }
    }
}

// MARK: - DatePickerHeaderViewDelegate

extension DatePicker: DatePickerHeaderViewDelegate {
    func didTapLeftArrow(in headerView: DatePickerHeaderView) {
        let previousDate = calendar.previousMonth(for: calendarView.visibleDate)
        setVisibleDate(previousDate, animated: true)
    }

    func didTapRightArrow(in headerView: DatePickerHeaderView) {
        let nextDate = calendar.nextMonth(for: calendarView.visibleDate)
        setVisibleDate(nextDate, animated: true)
    }

    func willBeginMonthPickerToggleAnimation(in headerView: DatePickerHeaderView) -> (() -> Void) {
        if headerView.isMonthPickerToggled {
            // Add month picker to the hierarchy on demand,
            // instead of adding when initializing the component,
            // because UIPickerView initialization is heavy
            addSubview(monthPicker)
            monthPicker.isHidden = false
            setMonthPickerDate(calendarView.visibleDate, animated: false)
        } else {
            // Make calendar visible at the beginning
            // of month picker close animation
            calendarView.isHidden = false
        }

        return { [weak self] in
            self?.setMonthPickerAlpha(isVisible: headerView.isMonthPickerToggled)
        }
    }

    func didFinishMonthPickerToggleAnimation(in headerView: DatePickerHeaderView) {
        if headerView.isMonthPickerToggled {
            // Make calendar hidden at the end
            // of month picker open animation
            calendarView.isHidden = true
        } else {
            monthPicker.removeFromSuperview()
        }
    }
}

// MARK: - DatePickerCalendarViewDelegate

extension DatePicker: DatePickerCalendarViewDelegate {
    func didChangeVisibleDate(in calendarView: DatePickerCalendarView) {
        setVisibleDate(calendarView.visibleDate, animated: false)
    }

    func didChangeSelectedDates(in calendarView: DatePickerCalendarView) {
        sendActions(for: .valueChanged)
    }

    func calendarView(_ calendarView: DatePickerCalendarView, canSelectDate date: Date) -> Bool {
        return delegate?.datePicker(self, canSelectDate: date) ?? true
    }

    func calendarView(_ calendarView: DatePickerCalendarView,
                      didTapDate date: Date,
                      inRange range: ClosedRange<Date>) {

        delegate?.datePicker(self, didTapDate: date, inRange: range)
    }

    func calendarView(_ calendarView: DatePickerCalendarView,
                      canSelectDate date: Date,
                      inRange range: ClosedRange<Date>) -> Bool {

        return delegate?.datePicker(self, canSelectDate: date, inRange: range) ?? false
    }
}

// MARK: - DatePickerCalendarViewDataSource

extension DatePicker: DatePickerCalendarViewDataSource {
    func calendarView(_ calendarView: DatePickerCalendarView,
                      annotationForDate date: Date) -> String? {

        return dataSource?.datePicker(self, annotationForDate: date)
    }

    func calendarView(_ calendarView: DatePickerCalendarView,
                      rangeContainingDate date: Date) -> ClosedRange<Date>? {

        return dataSource?.datePicker(self, rangeContainingDate: date)
    }

    func calendarView(_ calendarView: DatePickerCalendarView,
                      backgroundColorForDate date: Date,
                      inRange range: ClosedRange<Date>) -> UIColor {

        return dataSource?.datePicker(self, backgroundColorForDate: date, inRange: range) ?? .clear
    }

    func calendarView(_ calendarView: DatePickerCalendarView, textColorForDate date: Date) -> UIColor? {
        return dataSource?.datePicker(self, textColorForDate: date)
    }
}

// MARK: - DatePickerMonthPickerDelegate

extension DatePicker: DatePickerMonthPickerDelegate {
    func didChangeSelectedDate(in monthPicker: DatePickerMonthPicker) {
        let monthDate = monthPicker.selectedDate
        setVisibleDate(monthDate, animated: false)

        // Move date range to the new month and year,
        // similar to the native UIDatePicker behavior
        if let dateRange,
           let movedDateRange = calendar.combine(days: dateRange, month: monthDate),
           !calendar.haveSameDays(dateRange, movedDateRange) {

            calendarView.setSelectedDates(movedDateRange)
            sendActions(for: .valueChanged)
        }
    }
}

// MARK: - Layout

private extension DatePicker {
    func setupLayout() {
        switch mode {
        case .date:
            addSubview(headerView)
            addSubview(calendarView)
        case .time:
            addSubview(timePicker)
        }
    }

    func layoutPickers() {
        switch mode {
        case .date:
            let headerSize = headerView.sizeThatFits(.init(
                width: bounds.width,
                height: .greatestFiniteMagnitude
            ))

            headerView.frame = .init(
                origin: .zero,
                size: .init(
                    width: bounds.width,
                    height: headerView.isHidden
                        ? 0
                        : headerSize.height
                )
            )

            calendarView.frame = .init(
                x: 0,
                y: headerView.frame.maxY,
                width: bounds.width,
                height: bounds.height - headerView.frame.maxY
            )

            // frame, т.к. monthPicker лежит в корне
            monthPicker.frame = calendarView.frame
        case .time:
            timePicker.frame = bounds
        }
    }
}

// MARK: - Internal

private extension DatePicker {
    var availableDates: ClosedRange<Date> {
        let defaultDateRange: ClosedRange<Date> = .distantPast ... .distantFuture
        let minimumDate = minimumDate ?? defaultDateRange.lowerBound
        let maximumDate = maximumDate ?? defaultDateRange.upperBound

        return minimumDate <= maximumDate
            ? minimumDate ... maximumDate
            : defaultDateRange
    }

    // MARK: - Property updaters

    func updateMode(oldMode: DatePickerMode) {
        layoutTransition(from: oldMode)

        switch mode {
        case .date(let dateSettings):
            calendarView.layoutDirection = dateSettings.layoutDirection
            calendarView.highlightsCurrentDate = dateSettings.highlightsCurrentDate
            calendarView.selectionBehavior = dateSettings.selectionBehavior

            setCurrentDateIfNeeded()
        case .time(let timeSettings):
            timePicker.minuteInterval = timeSettings.minuteInterval
        }
    }

    func updateAvailableDates() {
        let availableDates = availableDates

        switch mode {
        case .date:
            calendarView.availableDates = availableDates
            monthPicker.availableDates = availableDates
            setHeaderDate(calendarView.visibleDate)
        case .time:
            timePicker.minimumDate = availableDates.lowerBound
            timePicker.maximumDate = availableDates.upperBound
        }
    }

    func updateDateRange() {
        setDateRange(dateRange, animated: false)
    }

    func updateEnabledState() {
        switch mode {
        case .date:
            headerView.isEnabled = isEnabled
            calendarView.isEnabled = isEnabled
            monthPicker.isEnabled = isEnabled
        case .time:
            timePicker.isEnabled = isEnabled
        }
    }

    func updateHeaderVisibility() {
        switch mode {
        case .date(let dateSettings):
            let shouldHideHeader = dateSettings.layoutDirection == .vertical

            if shouldHideHeader != headerView.isHidden {
                headerView.isHidden = shouldHideHeader
                setMonthPickerVisibility(isVisible: !shouldHideHeader && headerView.isMonthPickerToggled)
                invalidateIntrinsicContentSize()
            }
        case .time:
            break
        }
    }

    // MARK: - Child components settings

    func setCurrentDateIfNeeded() {
        // Try to select current date only if there was no selected date already
        guard dateRange == nil || dateRange == calendar.referenceDateRange else { return }

        switch mode {
        case .date(let dateSettings):
            switch (dateSettings.currentDateSelection, dateSettings.selectionBehavior) {
            case (.on, _), (.automatic, .single):
                setDate(calendar.referenceDate, animated: false)
            default:
                setDate(nil, animated: false)
            }
        case .time:
            break
        }
    }

    func setVisibleDate(_ date: Date, animated: Bool) {
        setHeaderDate(date)

        if !calendar.haveSameMonth(date, calendarView.visibleDate) {
            calendarView.setVisibleDate(date, animated: animated)
        }

        if headerView.isMonthPickerToggled {
            setMonthPickerDate(date, animated: animated)
        }
    }

    func setHeaderDate(_ date: Date) {
        let previousDate = calendar.previousMonth(for: date)
        let nextDate = calendar.nextMonth(for: date)
        let availableDates = availableDates

        headerView.setDate(
            calendar.monthAndYearString(for: date),
            isLeftArrowEnabled: calendar.contains(month: previousDate, in: availableDates),
            isRightArrowEnabled: calendar.contains(month: nextDate, in: availableDates)
        )
    }

    func setMonthPickerDate(_ date: Date, animated: Bool) {
        guard !calendar.haveSameMonth(date, monthPicker.selectedDate) else { return }
        monthPicker.setSelectedDate(date, animated: animated)
    }

    func setMonthPickerVisibility(isVisible: Bool) {
        monthPicker.isHidden = !isVisible
        calendarView.isHidden = isVisible
        setMonthPickerAlpha(isVisible: isVisible)
    }

    func setMonthPickerAlpha(isVisible: Bool) {
        if isVisible {
            monthPicker.alpha = 1
            calendarView.alpha = 0
        } else {
            monthPicker.alpha = 0
            calendarView.alpha = 1
        }
    }

    // MARK: - Mode layout transition

    func layoutTransition(from oldMode: DatePickerMode) {
        switch (mode, oldMode) {
        case (.date, .time):
            timePicker.removeFromSuperview()

            setupLayout()

            if headerView.isMonthPickerToggled {
                // Restore month picker if it was visible before
                addSubview(monthPicker)
            }

            invalidateIntrinsicContentSize()
        case (.time, .date):
            headerView.removeFromSuperview()
            calendarView.removeFromSuperview()
            monthPicker.removeFromSuperview()

            setupLayout()

            invalidateIntrinsicContentSize()
        default:
            break
        }
    }

    // MARK: - Accessibility

    func updateAccessibility() {
        accessibilityIdentifier = settings.accessibility.ids.itself

        switch mode {
        case .date:
            break
        case .time:
            timePicker.accessibilityIdentifier = settings.accessibility.ids.timePicker
        }
    }
}
