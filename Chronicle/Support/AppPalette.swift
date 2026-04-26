import SwiftUI

enum AppPalette {
    static let rightEye = Color(red: 125 / 255, green: 211 / 255, blue: 252 / 255)
    static let leftEye = Color(red: 253 / 255, green: 164 / 255, blue: 175 / 255)
    static let hearing = Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let sectionBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    static let sleepCore = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let sleepDeep = rightEye
    static let sleepREM = Color(red: 196 / 255, green: 181 / 255, blue: 253 / 255)
    static let sleepAwake = leftEye
    static let sleepUnspecified = Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255)
}
