import Charts
import SwiftData
import SwiftUI

struct OpticalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PrescriptionRecord.testedAt, order: .reverse) private var records: [PrescriptionRecord]

    @State private var isPresentingNewRecord = false
    @State private var selectedRecord: PrescriptionRecord?
    @State private var selectedMetric: ChartMetric = .sph
    @State private var visibleEyes: Set<EyeSide> = Set(EyeSide.allCases)

    private var sortedRecords: [PrescriptionRecord] {
        records.sorted { $0.testedAt < $1.testedAt }
    }

    private var rightPoints: [ChartPoint] {
        selectedMetric.points(from: sortedRecords, eye: .right)
    }

    private var leftPoints: [ChartPoint] {
        selectedMetric.points(from: sortedRecords, eye: .left)
    }

    private var hasVisibleData: Bool {
        (visibleEyes.contains(.right) && rightPoints.count >= 2) || (visibleEyes.contains(.left) && leftPoints.count >= 2)
    }

    private var trendDescriptions: [String] {
        EyeSide.allCases.compactMap { eye in
            guard visibleEyes.contains(eye) else {
                return nil
            }

            return selectedMetric.trendDescription(for: sortedRecords, eye: eye)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("Trends") {
                            chartSection
                        }

                        Section("History") {
                            ForEach(records) { record in
                                Button {
                                    selectedRecord = record
                                } label: {
                                    PrescriptionRecordRow(record: record)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("optical-record-\(record.id.uuidString)")
                            }
                            .onDelete(perform: deleteRecords)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Optical")
            .toolbarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                addButton
            }
            .sheet(isPresented: $isPresentingNewRecord) {
                NavigationStack {
                    EntryFormView()
                }
            }
            .sheet(item: $selectedRecord) { record in
                NavigationStack {
                    EntryFormView(record: record)
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No prescriptions yet",
            systemImage: "eye",
            description: Text("Add your first prescription to start tracking changes over time.")
        )
    }

    private var addButton: some View {
        Button {
            isPresentingNewRecord = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(AppPalette.rightEye, in: Circle())
                .shadow(radius: 12, y: 6)
        }
        .padding()
        .accessibilityIdentifier("add-record-button")
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            metricPicker
            eyeToggleRow

            if hasVisibleData {
                chartCard
            } else {
                ContentUnavailableView(
                    "Not enough data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Add at least two values for the selected metric in one visible eye to see trends.")
                )
                .frame(minHeight: 220)
            }
        }
        .padding(.vertical, 8)
    }

    private var metricPicker: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(ChartMetric.allCases) { metric in
                Text(metric.title).tag(metric)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("metric-picker")
    }

    private var eyeToggleRow: some View {
        HStack(spacing: 12) {
            ForEach(EyeSide.allCases) { eye in
                Button {
                    toggle(eye)
                } label: {
                    Label(eye.shortTitle, systemImage: visibleEyes.contains(eye) ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .foregroundStyle(eye == .right ? AppPalette.rightEye : AppPalette.leftEye)
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedMetric.detailText)
                    .font(.headline)
                Text("Only real recorded values are plotted for each eye.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart {
                if visibleEyes.contains(.right) {
                    ForEach(rightPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.title, point.value),
                            series: .value("Eye", EyeSide.right.shortTitle)
                        )
                        .foregroundStyle(AppPalette.rightEye)
                        .interpolationMethod(selectedMetric.interpolationMethod)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.title, point.value)
                        )
                        .foregroundStyle(AppPalette.rightEye)
                    }
                }

                if visibleEyes.contains(.left) {
                    ForEach(leftPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.title, point.value),
                            series: .value("Eye", EyeSide.left.shortTitle)
                        )
                        .foregroundStyle(AppPalette.leftEye)
                        .interpolationMethod(selectedMetric.interpolationMethod)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(selectedMetric.title, point.value)
                        )
                        .foregroundStyle(AppPalette.leftEye)
                    }
                }
            }
            .frame(height: 260)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartYScale(domain: selectedMetric.yDomain)
            .chartYAxisLabel(selectedMetric.unit)

            if !trendDescriptions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trend")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(trendDescriptions, id: \.self) { description in
                        Text(description)
                            .font(.footnote)
                    }
                }
            }
        }
    }

    private func toggle(_ eye: EyeSide) {
        if visibleEyes.contains(eye), visibleEyes.count == 1 {
            return
        }

        if visibleEyes.contains(eye) {
            visibleEyes.remove(eye)
        } else {
            visibleEyes.insert(eye)
        }
    }

    private func deleteRecords(at offsets: IndexSet) {
        offsets.map { records[$0] }.forEach(modelContext.delete)
        try? modelContext.save()
    }
}

private struct PrescriptionRecordRow: View {
    let record: PrescriptionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Formatters.recordDate.string(from: record.testedAt))
                    .font(.headline)

                Spacer()

                if let practice = record.practice {
                    Text(practice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 12) {
                eyeSummary(title: "Right", colour: AppPalette.rightEye, sph: record.reSph, cyl: record.reCyl, axis: record.reAxis, add: record.reAdd)
                eyeSummary(title: "Left", colour: AppPalette.leftEye, sph: record.leSph, cyl: record.leCyl, axis: record.leAxis, add: record.leAdd)
            }

            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }

    private func eyeSummary(title: String, colour: Color, sph: Double?, cyl: Double?, axis: Int?, add: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: "circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(colour)
                .labelStyle(.titleAndIcon)

            Text(summaryText(sph: sph, cyl: cyl, axis: axis, add: add))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func summaryText(sph: Double?, cyl: Double?, axis: Int?, add: Double?) -> String {
        guard let sph else {
            return "Not recorded"
        }

        var parts = ["SPH \(String(format: "%+.2f", sph))"]

        if let cyl, let axis {
            parts.append("CYL \(String(format: "%+.2f", cyl)) × \(axis)")
        }

        if let add {
            parts.append("ADD \(String(format: "%+.2f", add))")
        }

        return parts.joined(separator: "\n")
    }
}

