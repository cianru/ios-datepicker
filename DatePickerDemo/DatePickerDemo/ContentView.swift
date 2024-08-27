import SwiftUI
import DatePicker

struct ContentView: View {
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy, HH:mm"
        return formatter
    }()

    private var dateIntervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateTemplate = "ddMMMMyyyy"
        return formatter
    }()

    @State private var showingAlert = false
    @State private var dateRange: ClosedRange<Date>?
    @State private var isEnabled = true
    @State private var layoutDirection: DatePickerDateModeSettings.LayoutDirection = .horizontal
    @State private var highlightsCurrentDate = true
    @State private var currentDateSelection: DatePickerDateModeSettings.CurrentDateSelection = .off
    @State private var limitAvailableDates = false
    @State private var disableSomeDates = false
    @State private var annotation = "1000"

    var body: some View {
        GeometryReader { metrics in
            List {

                DatePickerUIViewRepresentable(
                    dateRange: $dateRange,
                    isEnabled: $isEnabled,
                    layoutDirection: $layoutDirection,
                    highlightsCurrentDate: $highlightsCurrentDate,
                    currentDateSelection: $currentDateSelection,
                    limitAvailableDates: $limitAvailableDates,
                    disableSomeDates: $disableSomeDates,
                    annotation: $annotation
                ).frame(maxHeight: metrics.size.width * 1.5)

                Button("Show alert") {
                    showingAlert = true
                }.alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Message"),
                        dismissButton: .default(Text("OK"))
                    )
                }

                VStack(alignment: .leading) {
                    Text("Selected date").bold()

                    let selectedDate = dateRange.map {
                        $0.lowerBound != $0.upperBound
                            ? dateIntervalFormatter.string(from: $0.lowerBound, to: $0.upperBound)
                            : dateFormatter.string(from: $0.lowerBound)
                    } ?? "none"
                    Text("\(selectedDate)")
                }

                VStack(alignment: .leading) {
                    Text("State").bold()
                    Picker("", selection: $isEnabled) {
                        Text("enabled").tag(true)
                        Text("disabled").tag(false)
                    }.pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Layout direction").bold()
                    Picker("", selection: $layoutDirection) {
                        Text("horizontal")
                            .tag(DatePickerDateModeSettings.LayoutDirection.horizontal)
                        Text("vertical")
                            .tag(DatePickerDateModeSettings.LayoutDirection.vertical)
                    }.pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Highlights current date").bold()
                    Picker("", selection: $highlightsCurrentDate) {
                        Text("yes").tag(true)
                        Text("no").tag(false)
                    }.pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Current date selection").bold()
                    Picker("", selection: $currentDateSelection) {
                        Text("on").tag(DatePickerDateModeSettings.CurrentDateSelection.on)
                        Text("off").tag(DatePickerDateModeSettings.CurrentDateSelection.off)
                        Text("auto").tag(DatePickerDateModeSettings.CurrentDateSelection.automatic)
                    }.pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Limit available dates").bold()
                    Picker("", selection: $limitAvailableDates) {
                        Text("yes").tag(true)
                        Text("no").tag(false)
                    }.pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Disable some dates").bold()
                    Picker("", selection: $disableSomeDates) {
                        Text("yes").tag(true)
                        Text("no").tag(false)
                    }.pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Annotation").bold()
                    TextField("", text: $annotation)
                        .textFieldStyle(.roundedBorder)
                }

            }.listStyle(PlainListStyle())
        }
    }
}

#Preview {
    ContentView()
}
