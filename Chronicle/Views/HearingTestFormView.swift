import SwiftData
import SwiftUI
import UIKit

struct HearingTestFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let record: HearingTestRecord?

    @State private var formState: HearingTestFormState
    @State private var validationMessage: String?

    init(record: HearingTestRecord? = nil) {
        self.record = record
        _formState = State(initialValue: HearingTestFormState(record: record))
    }

    var body: some View {
        Form {
            Section("Appointment") {
                DatePicker("Test date", selection: $formState.testedAt, displayedComponents: .date)
                TextField("Provider", text: $formState.provider)
                    .textInputAutocapitalization(.words)
                TextField("Notes", text: $formState.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            HearingEarFormSection(
                title: "Right ear",
                colour: AppPalette.rightEye,
                thresholds: $formState.rightThresholds
            )

            HearingEarFormSection(
                title: "Left ear",
                colour: AppPalette.leftEye,
                thresholds: $formState.leftThresholds
            )
        }
        .navigationTitle(record == nil ? "New hearing test" : "Edit hearing test")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!formState.canSave)
                .accessibilityIdentifier("save-hearing-test-button")
            }
        }
        .alert("Unable to save", isPresented: alertIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "")
        }
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { validationMessage != nil },
            set: { if !$0 { validationMessage = nil } }
        )
    }

    private func save() {
        if let message = formState.validationMessage() {
            validationMessage = message
            return
        }

        let target = record ?? formState.makeRecord()
        formState.apply(to: target)

        if record == nil {
            modelContext.insert(target)
        }

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            validationMessage = "Chronicle could not save this hearing test."
        }
    }
}

private struct HearingEarFormSection: View {
    let title: String
    let colour: Color

    @Binding var thresholds: [HearingThresholdFormValue]

    var body: some View {
        Section {
            ForEach($thresholds) { $threshold in
                Toggle(isOn: $threshold.isIncluded.animation()) {
                    Text("\(threshold.frequencyHz) Hz")
                }
                .tint(colour)

                if threshold.isIncluded {
                    Stepper(value: $threshold.hearingLevelDBHL, in: -10...120, step: 5) {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            Text("\(Int(threshold.hearingLevelDBHL)) dB HL")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Label(title, systemImage: "ear")
                .foregroundStyle(colour)
        } footer: {
            Text("Lower dB HL means quieter sounds were heard at that pitch.")
        }
    }
}

