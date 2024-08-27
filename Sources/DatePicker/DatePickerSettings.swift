import UIKit

/// Date picker appearance and accessibility settings
public struct DatePickerSettings {
    /// Default global settings
    public static var `default` = DatePickerSettings()

    public var appearance = DatePickerAppearanceSettings()
    public var accessibility = DatePickerAccessibilitySettings()
    public init() {}
}

// MARK: - Appearance

public struct DatePickerAppearanceSettings {
    public struct Layout {
        public struct Units {
            /// Unit used to calculate internal insets and sizes
            public var unit: CGFloat = 4
            public init() {}
        }

        public struct Sizes {
            /// Tappable size of the controls,
            /// used for next month and previous month buttons
            public var tappableSize = CGSize(width: 40, height: 44)
            /// Width of the separators
            public var separatorWidth: CGFloat = 0.5
            /// Minimum calendar cell size
            public var minimumCellSize = CGSize(width: 24, height: 24)
            /// Optimal calendar cell size
            public var optimalCellSize = CGSize(width: 58, height: 50)
            /// Max content with for vertical layout
            public var maxContentWidth: CGFloat = 600
            public init() {}
        }

        public var units = Units()
        public var sizes = Sizes()
        public init() {}
    }

    public struct Colors {
        public struct Text {
            /// Primary text color, used for dates
            public var primary = UIColor.label
            /// Secondary text color, used for week days
            public var secondary = UIColor.secondaryLabel
            /// Disabled text color,
            /// used for unavailable dates or when `isEnabled == false`
            public var disabled = UIColor.tertiaryLabel
            /// Inverted text color, used for text in selected dates
            public var inverted = UIColor.systemBackground
            /// Accent text color, used for current date
            public var accent = UIColor.systemBlue
            public init() {}
        }

        public struct Control {
            /// Primary control color, used for buttons
            public var primary = UIColor.systemBlue
            /// Secondary control color, used for selected date range
            public var secondary = UIColor.systemBlue.withAlphaComponent(0.3)
            /// Disabled control color, used for disabled buttons and selections
            public var disabled = UIColor.systemGray3
            public init() {}
        }

        public struct Separator {
            /// Primary color used for separators
            public var primary = UIColor.separator
            public init() {}
        }

        public var text = Text()
        public var control = Control()
        public var separator = Separator()
        public init() {}
    }

    public struct Fonts {
        /// Date font, used in header
        public var date = UIFont.preferredFont(forTextStyle: .body)
        /// Week day font
        public var weekday = UIFont.preferredFont(forTextStyle: .subheadline)
        /// Month font, used in vertical layout headers
        public var month = UIFont.preferredFont(forTextStyle: .headline)
        /// Day font, used in calendar
        public var day = UIFont.preferredFont(forTextStyle: .body)
        /// Annotation font, used in calendar
        public var annotation = UIFont.preferredFont(forTextStyle: .footnote)
        public init() {}
    }

    public struct Images {
        /// Left chevron image, used for previous month button
        public var chevronLeft = UIImage(systemName: "chevron.left")
        /// Right chevron image, used for next month button
        public var chevronRight = UIImage(systemName: "chevron.right")
        /// Down chevron image, used for month picker button
        public var chevronDown = UIImage(systemName: "chevron.down")
        public init() {}
    }

    public struct Animations {
        /// Default animations duration, used in month picker
        public var duration: TimeInterval = 0.3
        public init() {}
    }

    public var layout = Layout()
    public var colors = Colors()
    public var fonts = Fonts()
    public var images = Images()
    public var animations = Animations()
    public init() {}
}

// MARK: - Accessibility

public struct DatePickerAccessibilitySettings {
    public struct Identifiers {
        /// Date picker component itself
        public var itself = "datePicker"
        /// Time picker wheel
        public var timePicker = "datePickerTimePicker"
        /// Month picker button in the header
        public var monthPickerButton = "datePickerMonthPickerButton"
        /// Annotations in the calendar
        public var annotation = "datePickerAnnotation"
        public init() {}
    }

    public struct Labels {
        /// Month picker button
        public var showMonthPicker = "Show month and year picker"
        public var hideMonthPicker = "Hide month and year picker"
        /// Next month and previous month buttons
        public var nextMonth = "Next month"
        public var previousMonth = "Previous month"
        /// Month picker wheel columns
        public var month = "Month"
        public var year = "Year"
        public init() {}
    }

    public var ids = Identifiers()
    public var labels = Labels()
    public init() {}
}
