import Foundation
import HealthKit
import Observation

protocol SleepHealthDataProviding {
    var isHealthDataAvailable: Bool { get }

    func requestReadAuthorisation() async throws
    func sleepSamples(from start: Date, to end: Date) async throws -> [RawSleepSample]
    func heartRateSamples(from start: Date, to end: Date) async throws -> [HeartRateSample]
}

struct HealthKitSleepDataProvider: SleepHealthDataProviding {
    private let store = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestReadAuthorisation() async throws {
        guard
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
            return
        }

        try await store.requestAuthorization(toShare: [], read: [sleepType, heartRateType])
    }

    func sleepSamples(from start: Date, to end: Date) async throws -> [RawSleepSample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let mappedSamples = (samples as? [HKCategorySample] ?? []).compactMap(mapSleepSample)
                continuation.resume(returning: mappedSamples)
            }

            store.execute(query)
        }
    }

    func heartRateSamples(from start: Date, to end: Date) async throws -> [HeartRateSample] {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                let mappedSamples = (samples as? [HKQuantitySample] ?? []).map { sample in
                    HeartRateSample(timestamp: sample.startDate, bpm: sample.quantity.doubleValue(for: unit))
                }
                continuation.resume(returning: mappedSamples)
            }

            store.execute(query)
        }
    }

    private func mapSleepSample(_ sample: HKCategorySample) -> RawSleepSample? {
        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
            return nil
        }

        let kind: RawSleepSample.Kind?
        switch value {
        case .inBed:
            kind = .inBed
        case .asleepCore:
            kind = .stage(.core)
        case .asleepDeep:
            kind = .stage(.deep)
        case .asleepREM:
            kind = .stage(.rem)
        case .awake:
            kind = .stage(.awake)
        case .asleepUnspecified:
            kind = .stage(.unspecified)
        @unknown default:
            kind = nil
        }

        guard let kind else {
            return nil
        }

        return RawSleepSample(kind: kind, start: sample.startDate, end: sample.endDate)
    }
}

@MainActor
@Observable
final class HealthKitManager {
    var nights: [SleepNight] = []
    var isLoading = false
    var hasRequestedPermission = false
    var errorMessage: String?

    private let healthDataProvider: SleepHealthDataProviding
    private let calendar: Calendar

    init(
        healthDataProvider: SleepHealthDataProviding = HealthKitSleepDataProvider(),
        calendar: Calendar = .current
    ) {
        self.healthDataProvider = healthDataProvider
        self.calendar = calendar
    }

    var isAvailable: Bool {
        healthDataProvider.isHealthDataAvailable
    }

    func requestPermissionAndLoad(range: SleepRange) async {
        guard isAvailable else {
            return
        }

        hasRequestedPermission = true
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await healthDataProvider.requestReadAuthorisation()
            nights = try await loadNights(range: range)
        } catch {
            errorMessage = "Chronicle could not read sleep data from Apple Health."
        }
    }

    func reload(range: SleepRange) async {
        guard isAvailable, hasRequestedPermission else {
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            nights = try await loadNights(range: range)
        } catch {
            errorMessage = "Chronicle could not refresh sleep data from Apple Health."
        }
    }

    private func loadNights(range: SleepRange) async throws -> [SleepNight] {
        let end = Date()
        let start = calendar.date(byAdding: range.component, to: end) ?? end.addingTimeInterval(-30 * 24 * 60 * 60)
        let rawSleepSamples = try await healthDataProvider.sleepSamples(from: start, to: end)
        let nightsWithoutHeartRate = SleepNightBuilder.makeNights(from: rawSleepSamples)

        var nightsWithHeartRate: [SleepNight] = []
        for night in nightsWithoutHeartRate {
            let heartRateSamples = try await healthDataProvider.heartRateSamples(from: night.inBedStart, to: night.inBedEnd)
            nightsWithHeartRate.append(night.replacingHeartRateSamples(heartRateSamples))
        }

        return nightsWithHeartRate.sorted { $0.date > $1.date }
    }
}
