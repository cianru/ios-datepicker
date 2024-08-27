import UIKit

protocol DatePickerCalendarViewDelegate: AnyObject {
    func didChangeVisibleDate(in calendarView: DatePickerCalendarView)
    func didChangeSelectedDates(in calendarView: DatePickerCalendarView)

    func calendarView(_ calendarView: DatePickerCalendarView,
                      canSelectDate date: Date) -> Bool

    func calendarView(_ calendarView: DatePickerCalendarView,
                      didTapDate date: Date,
                      inRange range: ClosedRange<Date>)
    func calendarView(_ calendarView: DatePickerCalendarView,
                      canSelectDate date: Date,
                      inRange range: ClosedRange<Date>) -> Bool
}

protocol DatePickerCalendarViewDataSource: AnyObject {
    func calendarView(_ calendarView: DatePickerCalendarView,
                      annotationForDate date: Date) -> String?
    func calendarView(_ calendarView: DatePickerCalendarView, textColorForDate date: Date) -> UIColor?
    func calendarView(_ calendarView: DatePickerCalendarView,
                      rangeContainingDate date: Date) -> ClosedRange<Date>?
    func calendarView(_ calendarView: DatePickerCalendarView,
                      backgroundColorForDate date: Date,
                      inRange range: ClosedRange<Date>) -> UIColor
}

final class DatePickerCalendarView: UIView {
    weak var delegate: DatePickerCalendarViewDelegate?
    weak var dataSource: DatePickerCalendarViewDataSource?

    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            weekdaysView.isEnabled = isEnabled
            collectionView.isUserInteractionEnabled = isEnabled
            reloadCollectionView()
        }
    }

    var layoutDirection: DatePickerDateModeSettings.LayoutDirection = .horizontal {
        didSet {
            guard layoutDirection != oldValue else { return }
            updateLayoutDirection()
            updateWeekdaysSeparator()
        }
    }

    var selectionBehavior: DatePickerDateModeSettings.SelectionBehavior = .single {
        didSet {
            guard selectionBehavior != oldValue else { return }
            updateSelectedDates()
        }
    }

    var highlightsCurrentDate = true {
        didSet {
            guard highlightsCurrentDate != oldValue else { return }
            reloadCollectionView()
        }
    }

    var availableDates: ClosedRange<Date> = .distantPast ... .distantFuture {
        didSet {
            guard availableDates != oldValue else { return }
            updateContentSize()
            updateSelectedDates()
            updateVisibleDate()
            updateWeekdaysSeparator()
        }
    }

    private var allowsRangeSelection: Bool {
        switch selectionBehavior {
        case .single:
            return false
        case .range:
            return true
        }
    }

    private var rangeClampingBehavior: DatePickerDateModeSettings.RangeClampingBehavior {
        switch selectionBehavior {
        case .single:
            return .off
        case .range(let clampingBehavior):
            return clampingBehavior
        }
    }

    private(set) var visibleDate = Date.distantPast
    private(set) var selectedDates: ClosedRange<Date>?

    private var highlightedDates: ClosedRange<Date>?

    private lazy var weekdaysView = DatePickerWeekdaysView(settings: settings, weekdays: calendar.weekdayNames)

    private lazy var weekdaysSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = settings.appearance.colors.separator.primary
        return view
    }()

    private lazy var horizontalLayout = DatePickerHorizontalCollectionViewLayout(settings: settings)
    private lazy var verticalLayout = DatePickerVerticalCollectionViewLayout(settings: settings)

    private var collectionViewLayout: UICollectionViewLayout & DatePickerCollectionViewLayout {
        switch layoutDirection {
        case .horizontal:
            return horizontalLayout
        case .vertical:
            return verticalLayout
        }
    }

    private lazy var collectionView: DatePickerCollectionView = {
        let collectionView = DatePickerCollectionView(layout: collectionViewLayout)
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DatePickerCollectionViewCell.self,
                                forCellWithReuseIdentifier: "\(DatePickerCollectionViewCell.self)")
        collectionView.register(DatePickerHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "\(DatePickerHeaderReusableView.self)")
        return collectionView
    }()

    private let settings: DatePickerSettings
    private let calendar: DatePickerCalendar

    init(settings: DatePickerSettings, calendar: DatePickerCalendar) {
        self.settings = settings
        self.calendar = calendar
        super.init(frame: .zero)

        setupLayout()

        updateContentSize()
        updateLayoutDirection()
        updateWeekdaysSeparator()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCollectionView()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return collectionViewLayout.sizeThatFits(size)
    }

    func setVisibleDate(_ date: Date, animated: Bool) {
        let date = calendar.clamp(month: date, to: availableDates)
        let page = calendar.numberOfMonths(from: availableDates.lowerBound, to: date)

        collectionView.setCurrentPage(page, animated: animated)
        collectionView.isUserInteractionEnabled = !animated

        visibleDate = date
    }

    func setSelectedDates(_ dates: ClosedRange<Date>?) {
        if let dates {
            let dates = allowsRangeSelection
                ? dates
                : dates.lowerBound ... dates.lowerBound

            selectedDates = dates.clamped(to: availableDates)
        } else {
            selectedDates = nil
        }

        reloadCollectionView()
    }

    func reloadAllDates() {
        updateSelectedDates()
    }
}

// MARK: - UICollectionViewDataSource

extension DatePickerCalendarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "\(DatePickerCollectionViewCell.self)",
            for: indexPath
        ) as? DatePickerCollectionViewCell else {
            return UICollectionViewCell()
        }

        updateCell(cell, at: indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        guard let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "\(DatePickerHeaderReusableView.self)",
            for: indexPath
        ) as? DatePickerHeaderReusableView else {
            return UICollectionReusableView()
        }

        let date = startOfMonth(for: indexPath.section)
        let isAvailableDate = calendar.contains(month: date, in: availableDates)
        let monthString = calendar.monthAndYearString(for: date)

        view.settings = settings
        view.viewModel = .init(
            title: monthString,
            isEnabled: isEnabled && isAvailableDate
        )

        return view
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
            + collectionViewLayout.numberOfPreloadedPages.before
            + collectionViewLayout.numberOfPreloadedPages.after
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {

        return numberOfCells(in: section)
            + collectionViewLayout.numberOfSupplementaryViews(in: section)
    }
}

// MARK: - UICollectionViewDelegate

extension DatePickerCalendarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        // A little foolproof (and native behavior emulation):
        // avoid returning dates with a zero seconds (Y-m-d 00:00:00),
        // because the user of the component may try to convert
        // the received date to a string, and then convert this string back to a date,
        // having lost a time zone component, and getting a completely different day in the end
        let referenceTime = selectedDates?.lowerBound ?? Date()

        guard
            let startOfDay = startOfDay(for: indexPath),
            let date = calendar.combine(date: startOfDay, time: referenceTime)
        else {
            return
        }

        // Interactive range tap handling
        if let range = interactiveRange(for: date) {
            delegate?.calendarView(self, didTapDate: date, inRange: range)
            return
        }

        guard isAvailableDate(date) else {
            return
        }

        let oldSelectedDates = selectedDates

        if allowsRangeSelection,
           let selectedDates,
           selectedDates.lowerBound == selectedDates.upperBound,
           date > selectedDates.lowerBound {

            // Range selection is available if one date has already been selected,
            // and the next selected date is greater than first one
            setSelectedDates(clamp(
                dates: selectedDates.lowerBound ... date
            ))
        } else {
            setSelectedDates(date ... date)
        }

        notifyDidChangeSelectedDatesIfNeeded(oldDates: oldSelectedDates)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didHighlightItemAt indexPath: IndexPath) {

        guard let date = startOfDay(for: indexPath) else { return }
        updateRangeHighlightingIfNeeded(for: date, isHighlighted: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didUnhighlightItemAt indexPath: IndexPath) {

        guard let date = startOfDay(for: indexPath) else { return }
        updateRangeHighlightingIfNeeded(for: date, isHighlighted: false)
    }
}

// MARK: - UIScrollViewDelegate

extension DatePickerCalendarView: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollView.isUserInteractionEnabled = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateWeekdaysSeparator()

        let isScrolledByUser = scrollView.isTracking
            || scrollView.isDragging
            || scrollView.isDecelerating

        guard scrollView.isUserInteractionEnabled, isScrolledByUser else { return }

        let date = calendar.dateByAdding(
            months: collectionViewLayout.currentPage,
            to: calendar.startOfMonth(for: availableDates.lowerBound)
        )

        if calendar.contains(month: date, in: availableDates) {
            let oldVisibleDate = visibleDate
            visibleDate = date

            notifyDidChangeVisibleDateIfNeeded(oldDate: oldVisibleDate)
        }
    }
}

// MARK: - Layout

private extension DatePickerCalendarView {
    func setupLayout() {
        addSubview(weekdaysView)
        addSubview(collectionView)
        addSubview(weekdaysSeparator)
    }

    func layoutCollectionView() {
        let adjustedContentRect = collectionViewLayout.adjustedContentRect(for: bounds)

        let weekdaysSize = collectionViewLayout.rowSizeThatFits(.init(
            width: adjustedContentRect.width,
            height: bounds.height
        ))

        weekdaysView.frame = .init(
            origin: adjustedContentRect.origin,
            size: weekdaysSize
        )

        collectionView.frame = .init(
            x: 0,
            y: weekdaysView.frame.maxY,
            width: bounds.width,
            height: bounds.height - weekdaysView.frame.maxY
        )

        weekdaysSeparator.frame = collectionView.frame
        weekdaysSeparator.frame.size.height = settings.appearance.layout.sizes.separatorWidth
    }
}

// MARK: - Internal

private extension DatePickerCalendarView {
    func updateContentSize() {
        let numberOfMonths = calendar.numberOfMonths(
            from: availableDates.lowerBound,
            to: availableDates.upperBound
        )

        let numberOfPages = numberOfMonths + 1

        horizontalLayout.numberOfPages = numberOfPages
        horizontalLayout.invalidateLayout()

        verticalLayout.numberOfPages = numberOfPages
        verticalLayout.invalidateLayout()
    }

    func updateLayoutDirection() {
        collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
        collectionView.isPagingEnabled = collectionViewLayout.isPagingEnabled
        collectionView.alwaysBounceHorizontal = collectionViewLayout.alwaysBounceHorizontal
        collectionView.alwaysBounceVertical = collectionViewLayout.alwaysBounceVertical
    }

    func updateSelectedDates() {
        setSelectedDates(selectedDates.map { clamp(dates: $0) })
    }

    func updateVisibleDate() {
        let oldVisibleDate = visibleDate
        setVisibleDate(visibleDate, animated: false)

        notifyDidChangeVisibleDateIfNeeded(oldDate: oldVisibleDate)
    }

    func updateWeekdaysSeparator() {
        weekdaysSeparator.isHidden = layoutDirection != .vertical
            || collectionView.contentOffset.y <= 0
    }

    func notifyDidChangeVisibleDateIfNeeded(oldDate: Date) {
        guard !calendar.haveSameMonth(visibleDate, oldDate) else { return }
        delegate?.didChangeVisibleDate(in: self)
    }

    func notifyDidChangeSelectedDatesIfNeeded(oldDates: ClosedRange<Date>?) {
        guard !calendar.haveSameDays(selectedDates, oldDates) else { return }
        delegate?.didChangeSelectedDates(in: self)
    }

    func reloadCollectionView() {
        collectionView.reloadData()
    }

    func reloadCells(for dates: ClosedRange<Date>) {
        calendar.enumerate(days: dates) { date in
            let indexPath = indexPath(for: date)

            guard let cell = collectionView.cellForItem(at: indexPath)
                    as? DatePickerCollectionViewCell else {
                return true
            }

            updateCell(cell, at: indexPath)
            return true
        }
    }

    func updateCell(_ cell: DatePickerCollectionViewCell, at indexPath: IndexPath) {
        if let date = startOfDay(for: indexPath) {
            let dayString = calendar.dayString(for: date)
            let textColor = dataSource?.calendarView(self, textColorForDate: date)
            let annotation = dataSource?.calendarView(self, annotationForDate: date)
            let style = cellStyle(for: date)
            let rangeStyle = rangeStyle(for: date)
            let accessibilityLabel = calendar.accessibilityString(for: date)
                + (annotation.map { ", \($0)" } ?? "")

            cell.isHidden = false
            cell.settings = settings

            cell.viewModel = .init(
                day: dayString,
                textColor: textColor,
                annotation: annotation,
                style: style,
                rangeStyle: rangeStyle,
                isEnabled: isEnabled,
                accessibility: .init(
                    label: accessibilityLabel,
                    annotationID: settings.accessibility.ids.annotation
                )
            )
        } else {
            cell.isHidden = true
        }
    }

    func cellStyle(for date: Date) -> DatePickerCollectionViewCellStyle {
        if let selectedDates, calendar.contains(day: date, in: selectedDates) {
            if calendar.haveSameDay(selectedDates.lowerBound, selectedDates.upperBound) {
                // Single selected date
                return .selected(start: true, end: true)
            }

            if calendar.haveSameDay(date, selectedDates.lowerBound) {
                // Date range beginning
                return .selected(start: true, end: false)
            }

            if calendar.haveSameDay(date, selectedDates.upperBound) {
                // Date range end
                return .selected(start: false, end: true)
            }

            return .range
        }

        if !isAvailableDate(date) {
            return .unavailable
        }

        if highlightsCurrentDate, calendar.haveSameDay(date, Date()) {
            return .current
        }

        return .available
    }

    func rangeStyle(for date: Date) -> DatePickerCollectionViewCellRangeStyle? {
        guard
            let range = dataSource?.calendarView(self, rangeContainingDate: date),
            let backgroundColor = dataSource?.calendarView(self, backgroundColorForDate: date, inRange: range)
        else {
            return nil
        }

        let isHighlighted = highlightedDates
            .map { calendar.contains(day: date, in: $0) } ?? false

        return .init(
            color: backgroundColor,
            isHighlighted: isHighlighted,
            isStart: calendar.haveSameDay(date, range.lowerBound),
            isEnd: calendar.haveSameDay(date, range.upperBound)
        )
    }

    func isAvailableDate(_ date: Date) -> Bool {
        return calendar.contains(day: date, in: availableDates)
            && delegate?.calendarView(self, canSelectDate: date) ?? true
    }

    func isInteractiveDate(_ date: Date, in range: ClosedRange<Date>) -> Bool {
        return delegate?.calendarView(self, canSelectDate: date, inRange: range) != true
    }

    func interactiveRange(for date: Date) -> ClosedRange<Date>? {
        guard
            let range = dataSource?.calendarView(self, rangeContainingDate: date),
            isInteractiveDate(date, in: range)
        else {
            return nil
        }

        return range
    }

    func isInteractiveRangeDate(_ date: Date) -> Bool {
        return interactiveRange(for: date) != nil
    }

    func canSelectDate(_ date: Date) -> Bool {
        return isAvailableDate(date)
            && !isInteractiveRangeDate(date)
    }

    func updateRangeHighlightingIfNeeded(for date: Date, isHighlighted: Bool) {
        guard let range = interactiveRange(for: date) else { return }
        highlightedDates = isHighlighted ? range : nil
        reloadCells(for: range)
    }

    func clamp(dates: ClosedRange<Date>) -> ClosedRange<Date> {
        let clampedDates = dates.clamped(to: availableDates)

        guard rangeClampingBehavior == .untilFirstDisabled else {
            return clampedDates
        }

        let minDate = clampedDates.lowerBound
        let maxDate = clampedDates.upperBound
        var currentDate = minDate

        // Clamp range to the first date that is not available for selection
        calendar.enumerate(days: dates) { date in
            guard canSelectDate(date) else { return false }
            currentDate = date
            return true
        }

        if minDate == currentDate && minDate != maxDate {
            return maxDate ... maxDate
        } else {
            return minDate ... currentDate
        }
    }

    func numberOfCells(in section: Int) -> Int {
        let monthDate = startOfMonth(for: section)
        let monthDays = calendar.numberOfDays(in: monthDate)
        let firstWeekday = firstWeekday(for: monthDate)
        return monthDays + firstWeekday
    }

    func indexPath(for date: Date) -> IndexPath {
        let months = calendar.numberOfMonths(from: availableDates.lowerBound, to: date)
        let section = collectionViewLayout.section(for: months)
        let monthDate = calendar.startOfMonth(for: date)
        let firstWeekday = firstWeekday(for: monthDate)
        let cell = calendar.day(for: date) + firstWeekday - 1
        return collectionViewLayout.indexPath(cell: cell, section: section)
    }

    func startOfDay(for indexPath: IndexPath) -> Date? {
        let monthDate = startOfMonth(for: indexPath.section)
        let monthDays = calendar.numberOfDays(in: monthDate)
        let firstWeekday = firstWeekday(for: monthDate)
        let day = collectionViewLayout.cell(from: indexPath) - firstWeekday
        guard (0..<monthDays).contains(day) else { return nil }
        return calendar.dateByAdding(days: day, to: monthDate)
    }

    func startOfMonth(for section: Int) -> Date {
        let months = collectionViewLayout.page(for: section)

        return calendar.dateByAdding(
            months: months,
            to: calendar.startOfMonth(for: availableDates.lowerBound)
        )
    }

    func firstWeekday(for date: Date) -> Int {
        let weekday = calendar.weekday(for: date)
        return (weekday + collectionViewLayout.numberOfColumns)
            % collectionViewLayout.numberOfColumns
    }
}
