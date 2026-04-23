import SwiftData
import SwiftUI
import UIKit

struct EntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let record: PrescriptionRecord?

    @State private var formState: PrescriptionFormState
    @State private var validationMessage: String?

    init(record: PrescriptionRecord? = nil) {
        self.record = record
        _formState = State(initialValue: PrescriptionFormState(record: record))
    }

    var body: some View {
        Form {
            Section("Visit") {
                DatePicker("Test date", selection: $formState.testedAt, displayedComponents: .date)
                TextField("Practice", text: $formState.practice)
                    .textInputAutocapitalization(.words)
                TextField("Notes", text: $formState.notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            EyeSectionView(
                title: "Right eye",
                colour: AppPalette.rightEye,
                includesEye: $formState.includesRightEye,
                sphValue: $formState.rightSph,
                includesCylinder: $formState.includesRightCylinder,
                cylinderValue: $formState.rightCyl,
                axisText: $formState.rightAxisText,
                includesAdd: $formState.includesRightAdd,
                addValue: $formState.rightAdd
            )

            EyeSectionView(
                title: "Left eye",
                colour: AppPalette.leftEye,
                includesEye: $formState.includesLeftEye,
                sphValue: $formState.leftSph,
                includesCylinder: $formState.includesLeftCylinder,
                cylinderValue: $formState.leftCyl,
                axisText: $formState.leftAxisText,
                includesAdd: $formState.includesLeftAdd,
                addValue: $formState.leftAdd
            )
        }
        .navigationTitle(record == nil ? "New prescription" : "Edit prescription")
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
                .accessibilityIdentifier("save-record-button")
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
            validationMessage = "Chronicle could not save this prescription."
        }
    }
}

private struct EyeSectionView: View {
    let title: String
    let colour: Color

    @Binding var includesEye: Bool
    @Binding var sphValue: Double
    @Binding var includesCylinder: Bool
    @Binding var cylinderValue: Double
    @Binding var axisText: String
    @Binding var includesAdd: Bool
    @Binding var addValue: Double

    var body: some View {
        Section {
            Toggle("Include \(title.lowercased())", isOn: $includesEye.animation())
                .tint(colour)

            if includesEye {
                signedStepper(title: "SPH", value: $sphValue, range: -20.0...10.0)

                Toggle("Include cylinder and axis", isOn: $includesCylinder.animation())
                    .tint(colour)

                if includesCylinder {
                    signedStepper(title: "CYL", value: $cylinderValue, range: -10.0...0.0)

                    TextField("Axis (0 - 180)", text: $axisText)
                        .keyboardType(.numberPad)
                }

                Toggle("Reading addition", isOn: $includesAdd.animation())
                    .tint(colour)

                if includesAdd {
                    signedStepper(title: "ADD", value: $addValue, range: 0.0...4.0, alwaysShowSign: true)
                }
            }
        } header: {
            Label(title, systemImage: "circle.fill")
                .foregroundStyle(colour)
        }
    }

    private func signedStepper(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        alwaysShowSign: Bool = true
    ) -> some View {
        Stepper(value: value, in: range, step: 0.25) {
            HStack {
                Text(title)
                Spacer()
                Text(formatted(value.wrappedValue, alwaysShowSign: alwaysShowSign))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatted(_ value: Double, alwaysShowSign: Bool) -> String {
        let sign = value > 0 || (alwaysShowSign && value == 0) ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))"
    }
}
