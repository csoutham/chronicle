import Charts
import SwiftData
import SwiftUI

struct ChartsView: View {
    @Query(sort: \PrescriptionRecord.testedAt) private var records: [PrescriptionRecord]

    @State private var selectedMetric: ChartMetric = .sph
    @State private var visibleEyes: Set<EyeSide> = Set(EyeSide.allCases)

    private var rightPoints: [ChartPoint] {
        selectedMetric.points(from: records, eye: .right)
    }

    private var leftPoints: [ChartPoint] {
        selectedMetric.points(from: records, eye: .left)
    }

    private var hasVisibleData: Bool {
        (visibleEyes.contains(.right) && rightPoints.count >= 2) || (visibleEyes.contains(.left) && leftPoints.count >= 2)
    }

    private var trendDescriptions: [String] {
        EyeSide.allCases.compactMap { eye in
            guard visibleEyes.contains(eye) else {
                return nil
            }

            return selectedMetric.trendDescription(for: records, eye: eye)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    metricPicker
                    eyeToggleRow

                    if hasVisibleData {
                        chartCard
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .navigationTitle("Charts")
            .background(Color(uiColor: .systemGroupedBackground))
        }
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
                            y: .value("Right", point.value)
                        )
                        .foregroundStyle(AppPalette.rightEye)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Right", point.value)
                        )
                        .foregroundStyle(AppPalette.rightEye)
                    }
                }

                if visibleEyes.contains(.left) {
                    ForEach(leftPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Left", point.value)
                        )
                        .foregroundStyle(AppPalette.leftEye)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Left", point.value)
                        )
                        .foregroundStyle(AppPalette.leftEye)
                    }
                }
            }
            .frame(height: 260)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
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
        .padding()
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var emptyState: some View {
        if records.isEmpty {
            ContentUnavailableView(
                "No records yet",
                systemImage: "eye",
                description: Text("Add your first prescription to see trends.")
            )
        } else {
            ContentUnavailableView(
                "Not enough data",
                systemImage: "chart.xyaxis.line",
                description: Text("Add at least two values for the selected metric in one visible eye to see trends.")
            )
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
}
