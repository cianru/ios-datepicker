import UIKit

final class DatePickerWeekdaysView: UIView {
    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            updateColors()
        }
    }

    private lazy var labels = weekdays.map { makeWeekdayLabel(text: $0) }

    private let settings: DatePickerSettings
    private let weekdays: [String]

    init(settings: DatePickerSettings, weekdays: [String]) {
        self.settings = settings
        self.weekdays = weekdays
        super.init(frame: .zero)

        setupLayout()
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutWeekdays()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }
}

// MARK: - Layout

private extension DatePickerWeekdaysView {
    func setupLayout() {
        for label in labels {
            addSubview(label)
        }
    }

    func layoutWeekdays() {
        guard bounds.width > 0, labels.count > 0 else { return }

        let labelWidth = bounds.width / CGFloat(labels.count)
        let labelHeight = bounds.height

        for (index, label) in labels.enumerated() {
            label.frame.origin = .init(x: labelWidth * CGFloat(index), y: 0)
            label.frame.size = .init(width: labelWidth, height: labelHeight)
        }
    }

    func makeWeekdayLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = settings.appearance.fonts.weekday
        label.textAlignment = .center
        label.text = text
        return label
    }
}

// MARK: - Appearance

private extension DatePickerWeekdaysView {
    var isDimmed: Bool { tintAdjustmentMode == .dimmed || !isEnabled }

    func updateColors() {
        for label in labels {
            label.textColor = isDimmed
                ? settings.appearance.colors.text.disabled
                : settings.appearance.colors.text.secondary
        }
    }
}
