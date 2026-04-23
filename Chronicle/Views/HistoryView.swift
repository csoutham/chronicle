import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PrescriptionRecord.testedAt, order: .reverse) private var records: [PrescriptionRecord]

    @State private var isPresentingNewRecord = false
    @State private var selectedRecord: PrescriptionRecord?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No records yet",
                        systemImage: "eye",
                        description: Text("Add your first prescription to start tracking changes over time.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            Button {
                                selectedRecord = record
                            } label: {
                                PrescriptionRecordRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("history-record-\(record.id.uuidString)")
                        }
                        .onDelete(perform: deleteRecords)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
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
