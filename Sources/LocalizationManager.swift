import Foundation
import Combine
import AppKit

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var strings: [String: String] = [:]
    private(set) var localesDirectory: URL

    /// 기본 영어 폴백 문자열
    private let fallbackStrings: [String: String] = [
        "language.name": "English",
        "menubar.charging_format": " %.1fW",
        "menu.charger_connected": "🔌 Charger Connected",
        "menu.charging": "⚡ Charging",
        "menu.fully_charged": "✅ Fully Charged",
        "menu.not_charging": "⏸️ Not Charging",
        "menu.adapter_max_na": "Adapter Max: --",
        "menu.current_charging_na": "Charging: --",
        "menu.voltage_na": "Voltage: --",
        "menu.amperage_na": "Current: --",
        "menu.adapter_info_na": "Adapter: --",
        "menu.health_na": "💚 Health: --",
        "menu.cycles_na": "🔄 Cycles: --",
        "menu.temperature_na": "🌡️ Temp: --",
        "menu.time_remaining_na": "⏱️ --",
        "menu.system_power_na": "💻 System: --",
        "settings.charging_items": "Charging Info",
        "settings.battery_items": "Battery & System",
        "menu.on_battery": "🔋 On Battery",
        "menu.adapter_max_format": "Adapter Max: %dW",
        "menu.current_charging_format": "Charging: %.1fW",
        "menu.voltage_format": "Voltage: %.2fV",
        "menu.amperage_format": "Current: %.2fA",
        "menu.adapter_info": "Adapter:",
        "menu.battery_format": "🔋 Battery: %d%%",
        "menu.health_format": "💚 Health: %d%%",
        "menu.cycles_format": "🔄 Cycles: %d",
        "menu.temperature_format": "🌡️ Temp: %.1f°C",
        "menu.time_full_hm_format": "⏱️ Full in: %dh %dm",
        "menu.time_full_m_format": "⏱️ Full in: %dm",
        "menu.time_left_hm_format": "⏱️ Left: %dh %dm",
        "menu.time_left_m_format": "⏱️ Left: %dm",
        "menu.system_power_format": "💻 System: %.1fW",
        "menu.system_power_est_format": "💻 System: ~%.1fW",
        "menu.settings": "⚙️ Settings…",
        "menu.quit": "Quit",
        "notification.connected_title": "Charger Connected",
        "notification.connected_body": "Charger connected ⚡",
        "notification.disconnected_title": "Charger Disconnected",
        "notification.disconnected_body": "Charger disconnected 🔌",
        "notification.detail_title": "Charger Details",
        "notification.detail_wva_format": "%dW ⚡ — %.1fV / %.2fA",
        "notification.detail_w_format": "%dW ⚡",
        "settings.title": "MoruGauge Settings",
        "settings.general": "General",
        "settings.update_interval": "Update Interval",
        "settings.seconds_format": "%ds",
        "settings.language": "Language",
        "settings.notifications": "Notifications",
        "settings.notify_on_connect": "Charger Connected",
        "settings.notify_on_disconnect": "Charger Disconnected",
        "settings.notify_detailed_info": "Show Detailed Info (W / V / A)",
        "settings.notify_silent": "Silent (No Sound)",
        "settings.visible_items": "Visible Menu Items",
        "settings.show_charging_status": "Charging Status",
        "settings.show_adapter_wattage": "Adapter Wattage",
        "settings.show_current_wattage": "Current Power",
        "settings.show_voltage": "Voltage",
        "settings.show_amperage": "Current (A)",
        "settings.show_adapter_info": "Adapter Details",
        "settings.show_battery_level": "Battery Level",
        "settings.show_battery_health": "Battery Health",
        "settings.show_cycle_count": "Cycle Count",
        "settings.show_temperature": "Temperature",
        "settings.show_time_remaining": "Time Remaining",
        "settings.show_system_power": "System Power",
        "settings.translations": "Translations",
        "settings.open_folder": "Open Translations Folder",
        "settings.translations_help": "Add .json files to create new translations"
    ]

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        localesDirectory = appSupport.appendingPathComponent("morugauge").appendingPathComponent("Locales")
        ensureLocalesDirectory()
        syncBuiltInLocales()
    }

    func initialize() {
        loadLanguage(AppSettings.shared.language)
    }

    // MARK: - 번역 문자열
    func get(_ key: String) -> String {
        strings[key] ?? fallbackStrings[key] ?? key
    }

    func format(_ key: String, _ args: CVarArg...) -> String {
        let template = strings[key] ?? fallbackStrings[key] ?? key
        return String(format: template, arguments: args)
    }

    // MARK: - 언어 로드
    func loadLanguage(_ code: String) {
        let filePath = localesDirectory.appendingPathComponent("\(code).json")
        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            strings = fallbackStrings
            return
        }
        strings = json
    }

    // MARK: - 사용 가능한 언어
    func availableLanguages() -> [(code: String, name: String)] {
        var result: [(code: String, name: String)] = []
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: localesDirectory.path) else {
            return [("en-us", "English")]
        }
        for file in contents where file.hasSuffix(".json") {
            let code = String(file.dropLast(5))
            let name = languageName(for: code) ?? code
            result.append((code: code, name: name))
        }
        return result.isEmpty ? [("en-us", "English")] : result.sorted { $0.code < $1.code }
    }

    private func languageName(for code: String) -> String? {
        let path = localesDirectory.appendingPathComponent("\(code).json")
        guard let data = try? Data(contentsOf: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return nil }
        return json["language.name"]
    }

    // MARK: - Locales 동기화
    private func ensureLocalesDirectory() {
        if !FileManager.default.fileExists(atPath: localesDirectory.path) {
            try? FileManager.default.createDirectory(at: localesDirectory, withIntermediateDirectories: true)
        }
    }

    /// 번들의 번역 파일을 Application Support로 복사/머지
    /// - 새 파일: 그대로 복사
    /// - 기존 파일: 누락된 키만 추가 (사용자 수정 보존)
    private func syncBuiltInLocales() {
        let fm = FileManager.default
        guard let bundleResPath = Bundle.main.resourcePath else { return }
        let bundleLocales = (bundleResPath as NSString).appendingPathComponent("Locales")
        guard fm.fileExists(atPath: bundleLocales),
              let files = try? fm.contentsOfDirectory(atPath: bundleLocales) else { return }

        for file in files where file.hasSuffix(".json") {
            let src = (bundleLocales as NSString).appendingPathComponent(file)
            let dst = localesDirectory.appendingPathComponent(file)

            if fm.fileExists(atPath: dst.path) {
                // 기존 파일에 누락 키 머지
                mergeNewKeys(from: src, into: dst.path)
            } else {
                try? fm.copyItem(atPath: src, toPath: dst.path)
            }
        }
    }

    /// 소스 JSON의 새 키를 대상 JSON에 추가 (기존 값 보존)
    private func mergeNewKeys(from sourcePath: String, into destPath: String) {
        guard let srcData = try? Data(contentsOf: URL(fileURLWithPath: sourcePath)),
              let srcJson = try? JSONSerialization.jsonObject(with: srcData) as? [String: String],
              let dstData = try? Data(contentsOf: URL(fileURLWithPath: destPath)),
              var dstJson = try? JSONSerialization.jsonObject(with: dstData) as? [String: String] else { return }

        var updated = false
        for (key, value) in srcJson where dstJson[key] == nil {
            dstJson[key] = value
            updated = true
        }

        if updated {
            if let data = try? JSONSerialization.data(withJSONObject: dstJson, options: [.prettyPrinted, .sortedKeys]) {
                try? data.write(to: URL(fileURLWithPath: destPath))
            }
        }
    }

    func openLocalesFolder() {
        NSWorkspace.shared.open(localesDirectory)
    }
}
