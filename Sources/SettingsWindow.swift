import SwiftUI
import Cocoa

class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if let existingWindow = window {
            existingWindow.title = LocalizationManager.shared.get("settings.title")
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(
            settings: AppSettings.shared,
            l10n: LocalizationManager.shared
        )
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 720),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.contentViewController = hostingController
        newWindow.title = LocalizationManager.shared.get("settings.title")
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var l10n: LocalizationManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                generalSection
                notificationsSection
                chargingItemsSection
                batteryItemsSection
                translationsSection
            }
            .padding(20)
        }
        .frame(width: 440, height: 700)
    }

    // MARK: - 일반
    private var generalSection: some View {
        GroupBox(label: Label(l10n.get("settings.general"), systemImage: "gear")) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(l10n.get("settings.update_interval")).font(.headline)
                    HStack {
                        Slider(value: $settings.updateInterval, in: 1...30, step: 1)
                        Text(l10n.format("settings.seconds_format", Int(settings.updateInterval)))
                            .frame(width: 40, alignment: .trailing).monospacedDigit()
                    }
                }
                Divider()
                HStack {
                    Text(l10n.get("settings.language")).font(.headline)
                    Spacer()
                    Picker("", selection: $settings.language) {
                        ForEach(l10n.availableLanguages(), id: \.code) { lang in
                            Text("\(lang.name) (\(lang.code))").tag(lang.code)
                        }
                    }.frame(width: 200)
                }
            }.padding(8)
        }
    }

    // MARK: - 알림
    private var notificationsSection: some View {
        GroupBox(label: Label(l10n.get("settings.notifications"), systemImage: "bell")) {
            VStack(alignment: .leading, spacing: 6) {
                SettingsToggle(l10n.get("settings.notify_on_connect"), isOn: $settings.notifyOnConnect)
                if settings.notifyOnConnect {
                    SettingsToggle(l10n.get("settings.notify_detailed_info"), isOn: $settings.notifyDetailedInfo)
                        .padding(.leading, 20)
                }
                Divider()
                SettingsToggle(l10n.get("settings.notify_on_disconnect"), isOn: $settings.notifyOnDisconnect)
                Divider()
                SettingsToggle(l10n.get("settings.notify_silent"), isOn: $settings.notifySilent)
            }.padding(8)
        }
    }

    // MARK: - 충전 정보 (충전기 연결 시 표시)
    private var chargingItemsSection: some View {
        GroupBox(label: Label(l10n.get("settings.charging_items"), systemImage: "bolt.fill")) {
            VStack(alignment: .leading, spacing: 6) {
                SettingsToggle(l10n.get("settings.show_charging_status"), isOn: $settings.showChargingStatus)
                SettingsToggle(l10n.get("settings.show_adapter_wattage"), isOn: $settings.showAdapterWattage)
                SettingsToggle(l10n.get("settings.show_current_wattage"), isOn: $settings.showCurrentWattage)
                SettingsToggle(l10n.get("settings.show_voltage"), isOn: $settings.showVoltage)
                SettingsToggle(l10n.get("settings.show_amperage"), isOn: $settings.showAmperage)
                SettingsToggle(l10n.get("settings.show_adapter_info"), isOn: $settings.showAdapterInfo)
            }.padding(8)
        }
    }

    // MARK: - 배터리 및 시스템 (항상 표시)
    private var batteryItemsSection: some View {
        GroupBox(label: Label(l10n.get("settings.battery_items"), systemImage: "battery.100")) {
            VStack(alignment: .leading, spacing: 6) {
                SettingsToggle(l10n.get("settings.show_battery_level"), isOn: $settings.showBatteryLevel)
                SettingsToggle(l10n.get("settings.show_battery_health"), isOn: $settings.showBatteryHealth)
                SettingsToggle(l10n.get("settings.show_cycle_count"), isOn: $settings.showCycleCount)
                SettingsToggle(l10n.get("settings.show_temperature"), isOn: $settings.showTemperature)
                SettingsToggle(l10n.get("settings.show_time_remaining"), isOn: $settings.showTimeRemaining)
                SettingsToggle(l10n.get("settings.show_system_power"), isOn: $settings.showSystemPower)
            }.padding(8)
        }
    }

    // MARK: - 번역
    private var translationsSection: some View {
        GroupBox(label: Label(l10n.get("settings.translations"), systemImage: "globe")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n.get("settings.translations_help")).font(.caption).foregroundColor(.secondary)
                Button(action: { LocalizationManager.shared.openLocalesFolder() }) {
                    Label(l10n.get("settings.open_folder"), systemImage: "folder")
                }
            }.padding(8)
        }
    }
}

struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    init(_ label: String, isOn: Binding<Bool>) { self.label = label; self._isOn = isOn }
    var body: some View { Toggle(label, isOn: $isOn).toggleStyle(.checkbox) }
}
