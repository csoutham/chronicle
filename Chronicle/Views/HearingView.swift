import Charts
import SwiftData
import SwiftUI

struct HearingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HearingTestRecord.testedAt, order: .reverse) private var records: [HearingTestRecord]

    @State private var isPresentingNewRecord = false
    @State private var selectedRecord: HearingTestRecord?

    private var latestRecord: HearingTestRecord? {
        records.first
    }

    private var sortedRecords: [HearingTestRecord] {
        records.sorted { $0.testedAt < $1.testedAt }
    }

    private var trendDescriptions: [String] {
        HearingEarSide.allCases.compactMap { ear in
            HearingChartData.pureToneAverageTrendDescription(from: sortedRecords, ear: ear)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        if let latestRecord {
                            Section("Latest audiogram") {
                                latestAudiogramCard(record: latestRecord)
                            }
                        }

                        Section("History") {
                            ForEach(records) { record in
                                Button {
                                    selectedRecord = record
                                } label: {
                                    HearingRecordRow(record: record)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("hearing-record-\(record.id.uuidString)")
                            }
                            .onDelete(perform: deleteRecords)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Hearing")
            .toolbarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                addButton
            }
            .sheet(isPresented: $isPresentingNewRecord) {
                NavigationStack {
                    HearingTestFormView()
                }
            }
            .sheet(item: $selectedRecord) { record in
                NavigationStack {
                    HearingTestFormView(record: record)
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No hearing tests yet",
            systemImage: "ear",
            description: Text("Add your first audiogram from a professional hearing test report.")
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
                .background(AppPalette.hearing, in: Circle())
                .shadow(radius: 12, y: 6)
        }
        .padding()
        .accessibilityIdentifier("add-hearing-test-button")
    }

    private func latestAudiogramCard(record: HearingTestRecord) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Formatters.recordDate.string(from: record.testedAt))
                    .font(.headline)

                Text("Audiograms show the quietest sound heard at each frequency. Lower dB HL is better.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HearingAudiogramChart(record: record)
                .frame(height: 260)

            Text(HearingChartData.latestSummary(for: record))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !trendDescriptions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
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
        .padding(.vertical, 8)
    }

    private func deleteRecords(at offsets: IndexSet) {
        offsets.map { records[$0] }.forEach(modelContext.delete)
        try? modelContext.save()
    }
}

private struct HearingAudiogramChart: View {
    let record: HearingTestRecord

    private var rightPoints: [HearingThresholdPoint] {
        HearingChartData.thresholdPoints(from: record, ear: .right)
    }

    private var leftPoints: [HearingThresholdPoint] {
        HearingChartData.thresholdPoints(from: record, ear: .left)
    }

    var body: some View {
        Chart {
            ForEach(rightPoints) { point in
                LineMark(
                    x: .value("Frequency", point.frequencyHz),
                    y: .value("Right", point.hearingLevelDBHL)
                )
                .foregroundStyle(AppPalette.rightEye)
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Frequency", point.frequencyHz),
                    y: .value("Right", point.hearingLevelDBHL)
                )
                .foregroundStyle(AppPalette.rightEye)
            }

            ForEach(leftPoints) { point in
                LineMark(
                    x: .value("Frequency", point.frequencyHz),
                    y: .value("Left", point.hearingLevelDBHL)
                )
                .foregroundStyle(AppPalette.leftEye)
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Frequency", point.frequencyHz),
                    y: .value("Left", point.hearingLevelDBHL)
                )
                .foregroundStyle(AppPalette.leftEye)
            }
        }
        .chartXAxis {
            AxisMarks(values: HearingTestRecord.defaultFrequencies) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let frequency = value.as(Int.self) {
                        Text("\(frequency)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxisLabel("Frequency Hz")
        .chartYAxisLabel("dB HL")
    }
}

private struct HearingRecordRow: View {
    let record: HearingTestRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Formatters.recordDate.string(from: record.testedAt))
                    .font(.headline)

                Spacer()

                if let provider = record.provider {
                    Text(provider)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 12) {
                earSummary(ear: .right, colour: AppPalette.rightEye)
                earSummary(ear: .left, colour: AppPalette.leftEye)
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

    private func earSummary(ear: HearingEarSide, colour: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(ear.shortTitle, systemImage: "circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(colour)
                .labelStyle(.titleAndIcon)

            Text(summaryText(for: ear))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppPalette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func summaryText(for ear: HearingEarSide) -> String {
        let pointCount = record.thresholdPoints(for: ear).count
        guard pointCount > 0 else {
            return "Not recorded"
        }

        if let average = record.pureToneAverage(for: ear) {
            return "\(pointCount) points\nPTA \(HearingChartData.formattedDecibels(average, includeSign: false))"
        }

        return "\(pointCount) points\nPTA needs 500, 1000 and 2000 Hz"
    }
}
