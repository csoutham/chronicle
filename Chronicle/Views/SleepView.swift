import Charts
import SwiftUI
import UIKit

struct SleepView: View {
    @State private var manager = HealthKitManager()
    @State private var selectedRange: SleepRange = .thirtyDays
    @State private var selectedMetric: SleepChartMetric = .total
    @State private var selectedNight: SleepNight?

    private var sortedNights: [SleepNight] {
        manager.nights.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding()
            }
            .navigationTitle("Sleep")
            .background(Color(uiColor: .systemGroupedBackground))
            .task(id: selectedRange) {
                await manager.reload(range: selectedRange)
            }
            .sheet(item: $selectedNight) { night in
                SleepNightDetailView(night: night)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !manager.isAvailable {
            ContentUnavailableView(
                "Health data unavailable",
                systemImage: "heart.text.square",
                description: Text("Sleep trends need Apple Health data from a supported device.")
            )
        } else if !manager.hasRequestedPermission {
            permissionIntro
        } else if manager.isLoading {
            ProgressView("Loading sleep data")
                .frame(maxWidth: .infinity, minHeight: 240)
        } else if let errorMessage = manager.errorMessage {
            errorState(errorMessage)
        } else if sortedNights.isEmpty {
            emptyDataState
        } else {
            sleepContent
        }
    }

    private var permissionIntro: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "bed.double.fill")
                .font(.largeTitle)
                .foregroundStyle(AppPalette.sleepDeep)

            Text("Connect Apple Health")
                .font(.title2.weight(.semibold))

            Text("Chronicle reads sleep stages and overnight heart rate to show trends. Nothing is written back to Apple Health.")
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await manager.requestPermissionAndLoad(range: selectedRange)
                }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Could not load sleep data", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            VStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        await manager.reload(range: selectedRange)
                    }
                }

                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    UIApplication.shared.open(url)
                }
                .font(.footnote)
            }
        }
    }

    private var emptyDataState: some View {
        ContentUnavailableView(
            "No accessible sleep data",
            systemImage: "bed.double",
            description: Text("There may be no Watch sleep data in this range, or Apple Health access may not have been granted.")
        )
    }

    private var sleepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let latestNight = sortedNights.first {
                SleepSummaryCard(night: latestNight)
            }

            Picker("Range", selection: $selectedRange) {
                ForEach(SleepRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            Picker("Metric", selection: $selectedMetric) {
                ForEach(SleepChartMetric.allCases) { metric in
                    Text(metric.title).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("sleep-metric-picker")

            SleepChartCard(metric: selectedMetric, nights: sortedNights)

            VStack(alignment: .leading, spacing: 12) {
                Text("Recent nights")
                    .font(.headline)

                ForEach(sortedNights.prefix(14)) { night in
                    Button {
                        selectedNight = night
                    } label: {
                        SleepNightRow(night: night)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SleepSummaryCard: View {
    let night: SleepNight

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last night")
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(Formatters.duration.string(from: night.totalAsleep) ?? "No sleep")
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                Spacer()
                Text(Formatters.recordDate.string(from: night.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(Formatters.duration.string(from: night.totalInBed) ?? "0m") in bed · \(efficiencyText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                ForEach([SleepStageType.deep, .rem, .core, .awake], id: \.self) { stage in
                    Text("\(stage.title) \(Formatters.duration.string(from: night.minutes(for: stage) * 60) ?? "0m")")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(stage.colour.opacity(0.18), in: Capsule())
                        .foregroundStyle(stage.colour)
                }
            }

            if let averageHeartRate = night.averageHeartRate {
                Text("Average heart rate \(Int(averageHeartRate.rounded())) bpm")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var efficiencyText: String {
        Formatters.percent.string(from: NSNumber(value: night.efficiency)) ?? "\(Int((night.efficiency * 100).rounded()))%"
    }
}

private struct SleepChartCard: View {
    let metric: SleepChartMetric
    let nights: [SleepNight]

    private var durationPoints: [SleepDurationPoint] {
        SleepChartDataBuilder.durationPoints(for: metric, from: nights)
    }

    private var hasEnoughData: Bool {
        durationPoints.count >= 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(metric.title) sleep over time")
                    .font(.headline)

                Text("Each point is one night. Missing stage data is skipped rather than filled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if hasEnoughData {
                chart
                    .frame(height: 260)

                if let insight {
                    Text(insight)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let averageInsight {
                    Text(averageInsight)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView(
                    "Not enough data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("This trend needs real values from at least two nights in the selected range.")
                )
                .frame(minHeight: 220)
            }
        }
        .padding()
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var chart: some View {
        Chart(durationPoints) { point in
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Hours", point.hours)
            )
            .foregroundStyle(metric.colour)

            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Hours", point.hours)
            )
            .foregroundStyle(metric.colour)
        }
        .chartYAxisLabel("Hours")
    }

    private var insight: String? {
        SleepChartDataBuilder.durationTrendDescription(for: metric, from: nights)
    }

    private var averageInsight: String? {
        SleepChartDataBuilder.durationAverageDescription(for: metric, from: nights)
    }
}

private struct SleepNightRow: View {
    let night: SleepNight

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatters.recordDate.string(from: night.date))
                    .font(.subheadline.weight(.medium))
                Text("\(Formatters.duration.string(from: night.totalAsleep) ?? "0m") asleep · \(Formatters.percent.string(from: NSNumber(value: night.efficiency)) ?? "0%") efficiency")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SleepNightDetailView: View {
    let night: SleepNight

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("Time asleep", value: Formatters.duration.string(from: night.totalAsleep) ?? "0m")
                    LabeledContent("Time in bed", value: Formatters.duration.string(from: night.totalInBed) ?? "0m")
                    LabeledContent("Efficiency", value: Formatters.percent.string(from: NSNumber(value: night.efficiency)) ?? "0%")
                    if let averageHeartRate = night.averageHeartRate {
                        LabeledContent("Average heart rate", value: "\(Int(averageHeartRate.rounded())) bpm")
                    }
                }

                Section("Stages") {
                    ForEach(night.stages) { stage in
                        HStack {
                            Circle()
                                .fill(stage.stage.colour)
                                .frame(width: 10, height: 10)
                            Text(stage.stage.title)
                            Spacer()
                            Text(Formatters.duration.string(from: stage.duration) ?? "0m")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(Formatters.recordDate.string(from: night.date))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
