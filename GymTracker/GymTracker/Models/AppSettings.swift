import Foundation
import SwiftUI

class AppSettings: ObservableObject {

    @Published var accentColorHex: String {
        didSet { UserDefaults.standard.set(accentColorHex, forKey: Keys.accent) }
    }
    var accentColor: Color { Color(hex: accentColorHex) }

    @Published var weightUnit: WeightUnit {
        didSet { UserDefaults.standard.set(weightUnit.rawValue, forKey: Keys.weightUnit) }
    }

    @Published var fontSize: FontSize {
        didSet { UserDefaults.standard.set(fontSize.rawValue, forKey: Keys.fontSize) }
    }

    @Published var showRestTimes: Bool {
        didSet { UserDefaults.standard.set(showRestTimes, forKey: Keys.showRest) }
    }

    init() {
        let ud = UserDefaults.standard
        self.accentColorHex = ud.string(forKey: Keys.accent) ?? "FF6B35"
        self.weightUnit     = WeightUnit(rawValue: ud.string(forKey: Keys.weightUnit) ?? "") ?? .lbs
        self.fontSize       = FontSize(rawValue: ud.string(forKey: Keys.fontSize) ?? "") ?? .medium
        self.showRestTimes  = ud.object(forKey: Keys.showRest) as? Bool ?? true
    }

    enum WeightUnit: String, CaseIterable, Identifiable {
        case lbs, kg
        var id: String { rawValue }
        var label: String { rawValue.uppercased() }
    }

    enum FontSize: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        var id: String { rawValue }
        var bodySize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }

    private enum Keys {
        static let accent     = "accent_color"
        static let weightUnit = "weight_unit"
        static let fontSize   = "font_size"
        static let showRest   = "show_rest"
    }

    static let presetColors: [(name: String, hex: String)] = [
        ("Orange", "FF6B35"), ("Red",    "FF3B30"), ("Pink",   "FF2D55"),
        ("Purple", "BF5AF2"), ("Indigo", "5E5CE6"), ("Blue",   "0A84FF"),
        ("Teal",   "4ECDC4"), ("Green",  "30D158"), ("Yellow", "FFD60A"),
        ("Cyan",   "32ADE6"),
    ]
}
