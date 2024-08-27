import UIKit

protocol DatePickerHeaderViewDelegate: AnyObject {
    func didTapLeftArrow(in headerView: DatePickerHeaderView)
    func didTapRightArrow(in headerView: DatePickerHeaderView)

    func willBeginMonthPickerToggleAnimation(in headerView: DatePickerHeaderView) -> (() -> Void)
    func didFinishMonthPickerToggleAnimation(in headerView: DatePickerHeaderView)
}

final class DatePickerHeaderView: UIView {
    private struct Layout {
        let insets: UIEdgeInsets
        let dateInsets: UIEdgeInsets
        let dateChevronLeftOffset: CGFloat
        let dateControlMinimalRightOffset: CGFloat
        let arrowButtonsInset: CGFloat
        let arrowButtonRightOffset: CGFloat
        let arrowButtonSize: CGSize
    }

    private lazy var layout = Layout(
        insets: .init(
            top: settings.appearance.layout.units(4),
            left: settings.appearance.layout.units(1),
            bottom: settings.appearance.layout.units(3),
            right: settings.appearance.layout.units(1)
        ),
        dateInsets: .init(
            vertical: settings.appearance.layout.units(2)
        ),
        dateChevronLeftOffset: settings.appearance.layout.units(2),
        dateControlMinimalRightOffset: settings.appearance.layout.units(2),
        arrowButtonsInset: settings.appearance.layout.units(1),
        arrowButtonRightOffset: -settings.appearance.layout.units(1),
        arrowButtonSize: settings.appearance.layout.sizes.tappableSize
    )

    weak var delegate: DatePickerHeaderViewDelegate?

    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            dateControl.isEnabled = isEnabled
            leftArrowButton.isEnabled = isEnabled
            rightArrowButton.isEnabled = isEnabled
            updateColors()
        }
    }

    private(set) var isMonthPickerToggled = false

    private lazy var dateControl: UIButton = {
        let button = UIButton(type: .custom)
        button.addAction { [weak self] in self?.toggleMonthPicker() }
        return button
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = settings.appearance.fonts.date
        return label
    }()

    private lazy var dateChevronView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = settings.appearance.images.chevronDown
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var leftArrowButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(settings.appearance.images.chevronLeft, for: .normal)

        button.addAction { [weak self] in
            guard let self else { return }
            delegate?.didTapLeftArrow(in: self)
        }

        return button
    }()

    private lazy var rightArrowButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(settings.appearance.images.chevronRight, for: .normal)

        button.addAction { [weak self] in
            guard let self else { return }
            delegate?.didTapRightArrow(in: self)
        }

        return button
    }()

    private let settings: DatePickerSettings

    init(settings: DatePickerSettings) {
        self.settings = settings
        super.init(frame: .zero)

        setupLayout()

        updateColors()
        updateAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(UIView.layoutFittingExpandedSize)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let labelSize = dateLabel.sizeThatFits(.init(
            width: size.width - layout.insets.left,
            height: size.height - layout.insets.vertical
        ))

        return .init(
            width: layout.insets.left
                + labelSize.width
                + layout.dateChevronLeftOffset
                + dateChevronView.sizeThatFits(size).width
                + layout.dateControlMinimalRightOffset
                + leftArrowButton.sizeThatFits(size).width
                + layout.arrowButtonsInset
                + rightArrowButton.sizeThatFits(size).width
                + layout.arrowButtonRightOffset,
            height: layout.insets.vertical + labelSize.height
        )
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }

    func setDate(_ date: String, isLeftArrowEnabled: Bool, isRightArrowEnabled: Bool) {
        dateLabel.text = date
        leftArrowButton.isEnabled = isLeftArrowEnabled
        rightArrowButton.isEnabled = isRightArrowEnabled

        updateColors()
    }
}

// MARK: - Layout

private extension DatePickerHeaderView {
    func setupLayout() {
        addConstrainedSubview(dateControl, constraints: [
            dateControl.topAnchor.constraint(equalTo: topAnchor)
                .constant(layout.insets.top - layout.dateInsets.top),
            dateControl.leadingAnchor.constraint(equalTo: leadingAnchor)
                .constant(layout.insets.left - layout.dateInsets.left),
        ])

        dateControl.addConstrainedSubview(dateLabel, constraints: [
            dateLabel.topAnchor.constraint(equalTo: dateControl.topAnchor)
                .constant(layout.dateInsets.top),
            dateLabel.bottomAnchor.constraint(equalTo: dateControl.bottomAnchor)
                .constant(-layout.dateInsets.bottom),
            dateLabel.leadingAnchor.constraint(equalTo: dateControl.leadingAnchor),
        ])

        dateControl.addConstrainedSubview(dateChevronView, constraints: [
            dateChevronView.centerYAnchor.constraint(equalTo: dateControl.centerYAnchor),
            dateChevronView.trailingAnchor.constraint(equalTo: dateControl.trailingAnchor)
                .constant(layout.dateInsets.right),
            dateChevronView.leadingAnchor.constraint(equalTo: dateLabel.trailingAnchor)
                .constant(layout.dateChevronLeftOffset),
        ])

        addConstrainedSubview(rightArrowButton, constraints: [
            rightArrowButton.centerYAnchor.constraint(equalTo: dateControl.centerYAnchor),
            rightArrowButton.trailingAnchor.constraint(equalTo: trailingAnchor)
                .constant(-layout.arrowButtonRightOffset),
            rightArrowButton.widthAnchor.constraint(equalToConstant: layout.arrowButtonSize.width),
            rightArrowButton.heightAnchor.constraint(equalToConstant: layout.arrowButtonSize.height),
        ])

        addConstrainedSubview(leftArrowButton, constraints: [
            leftArrowButton.centerYAnchor.constraint(equalTo: dateControl.centerYAnchor),
            leftArrowButton.trailingAnchor.constraint(equalTo: rightArrowButton.leadingAnchor)
                .constant(-layout.arrowButtonsInset),
            leftArrowButton.widthAnchor.constraint(equalToConstant: layout.arrowButtonSize.width),
            leftArrowButton.heightAnchor.constraint(equalToConstant: layout.arrowButtonSize.height),
        ])
    }
}

// MARK: - Internal

private extension DatePickerHeaderView {
    func toggleMonthPicker() {
        isMonthPickerToggled = !isMonthPickerToggled

        let animations = delegate?.willBeginMonthPickerToggleAnimation(in: self)

        UIView.animate(withDuration: settings.appearance.animations.duration) {
            if self.isMonthPickerToggled {
                // -0.999, чтобы шеврон крутился против часовой стрелки,
                // иначе он крутится по часовой, т.к. это кратчайший путь для трансформации
                self.dateChevronView.transform = .identity.rotated(by: .pi * -0.999)
                self.leftArrowButton.alpha = 0
                self.rightArrowButton.alpha = 0
            } else {
                self.dateChevronView.transform = .identity
                self.leftArrowButton.alpha = 1
                self.rightArrowButton.alpha = 1
            }

            self.updateDateLabelColor()
            self.updateAccessibility()
            animations?()
        } completion: { _ in
            self.delegate?.didFinishMonthPickerToggleAnimation(in: self)
        }
    }
}

// MARK: - Accessibility

private extension DatePickerHeaderView {
    func updateAccessibility() {
        dateControl.isAccessibilityElement = true
        leftArrowButton.isAccessibilityElement = true
        rightArrowButton.isAccessibilityElement = true

        updateAccessibilityIdentifiers()
        updateAccessibilityLabels()
    }

    func updateAccessibilityIdentifiers() {
        dateControl.accessibilityIdentifier = settings.accessibility.ids.monthPickerButton
    }

    func updateAccessibilityLabels() {
        dateControl.accessibilityLabel = isMonthPickerToggled
            ? settings.accessibility.labels.hideMonthPicker
            : settings.accessibility.labels.showMonthPicker
        leftArrowButton.accessibilityLabel = settings.accessibility.labels.previousMonth
        rightArrowButton.accessibilityLabel = settings.accessibility.labels.nextMonth
    }
}

// MARK: - Appearance

private extension DatePickerHeaderView {
    var isDimmed: Bool { tintAdjustmentMode == .dimmed || !isEnabled }

    func updateColors() {
        updateDateLabelColor()
        updateDateChevronColor()
        updateArrowButtonColor()
    }

    func updateDateLabelColor() {
        if isDimmed {
            dateLabel.textColor = settings.appearance.colors.control.disabled
        } else {
            dateLabel.textColor = isMonthPickerToggled
                ? settings.appearance.colors.control.primary
                : settings.appearance.colors.text.primary
        }
    }

    func updateDateChevronColor() {
        dateChevronView.tintColor = isDimmed
            ? settings.appearance.colors.control.disabled
            : settings.appearance.colors.control.primary
    }

    func updateArrowButtonColor() {
        leftArrowButton.tintColor = isDimmed || !leftArrowButton.isEnabled
            ? settings.appearance.colors.control.disabled
            : settings.appearance.colors.control.primary
        rightArrowButton.tintColor = isDimmed || !rightArrowButton.isEnabled
            ? settings.appearance.colors.control.disabled
            : settings.appearance.colors.control.primary
    }
}
