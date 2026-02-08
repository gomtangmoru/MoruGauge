import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - 일반 설정
    @Published var updateInterval: Double {
        didSet { UserDefaults.standard.set(updateInterval, forKey: Keys.updateInterval) }
    }
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: Keys.language)
            LocalizationManager.shared.loadLanguage(language)
        }
    }

    // MARK: - 알림 설정
    @Published var notifyOnConnect: Bool {
        didSet { UserDefaults.standard.set(notifyOnConnect, forKey: Keys.notifyOnConnect) }
    }
    @Published var notifyOnDisconnect: Bool {
        didSet { UserDefaults.standard.set(notifyOnDisconnect, forKey: Keys.notifyOnDisconnect) }
    }
    @Published var notifyDetailedInfo: Bool {
        didSet { UserDefaults.standard.set(notifyDetailedInfo, forKey: Keys.notifyDetailedInfo) }
    }
    @Published var notifySilent: Bool {
        didSet { UserDefaults.standard.set(notifySilent, forKey: Keys.notifySilent) }
    }

    // MARK: - 메뉴 표시 항목 토글
    @Published var showChargingStatus: Bool {
        didSet { UserDefaults.standard.set(showChargingStatus, forKey: Keys.showChargingStatus) }
    }
    @Published var showAdapterWattage: Bool {
        didSet { UserDefaults.standard.set(showAdapterWattage, forKey: Keys.showAdapterWattage) }
    }
    @Published var showCurrentWattage: Bool {
        didSet { UserDefaults.standard.set(showCurrentWattage, forKey: Keys.showCurrentWattage) }
    }
    @Published var showVoltage: Bool {
        didSet { UserDefaults.standard.set(showVoltage, forKey: Keys.showVoltage) }
    }
    @Published var showAmperage: Bool {
        didSet { UserDefaults.standard.set(showAmperage, forKey: Keys.showAmperage) }
    }
    @Published var showAdapterInfo: Bool {
        didSet { UserDefaults.standard.set(showAdapterInfo, forKey: Keys.showAdapterInfo) }
    }
    @Published var showBatteryLevel: Bool {
        didSet { UserDefaults.standard.set(showBatteryLevel, forKey: Keys.showBatteryLevel) }
    }
    @Published var showBatteryHealth: Bool {
        didSet { UserDefaults.standard.set(showBatteryHealth, forKey: Keys.showBatteryHealth) }
    }
    @Published var showCycleCount: Bool {
        didSet { UserDefaults.standard.set(showCycleCount, forKey: Keys.showCycleCount) }
    }
    @Published var showTemperature: Bool {
        didSet { UserDefaults.standard.set(showTemperature, forKey: Keys.showTemperature) }
    }
    @Published var showTimeRemaining: Bool {
        didSet { UserDefaults.standard.set(showTimeRemaining, forKey: Keys.showTimeRemaining) }
    }
    @Published var showSystemPower: Bool {
        didSet { UserDefaults.standard.set(showSystemPower, forKey: Keys.showSystemPower) }
    }

    // MARK: - UserDefaults 키
    private enum Keys {
        static let updateInterval = "updateInterval"
        static let language = "language"
        static let notifyOnConnect = "notifyOnConnect"
        static let notifyOnDisconnect = "notifyOnDisconnect"
        static let notifyDetailedInfo = "notifyDetailedInfo"
        static let notifySilent = "notifySilent"
        static let showChargingStatus = "showChargingStatus"
        static let showAdapterWattage = "showAdapterWattage"
        static let showCurrentWattage = "showCurrentWattage"
        static let showVoltage = "showVoltage"
        static let showAmperage = "showAmperage"
        static let showAdapterInfo = "showAdapterInfo"
        static let showBatteryLevel = "showBatteryLevel"
        static let showBatteryHealth = "showBatteryHealth"
        static let showCycleCount = "showCycleCount"
        static let showTemperature = "showTemperature"
        static let showTimeRemaining = "showTimeRemaining"
        static let showSystemPower = "showSystemPower"
        static let hasLaunchedBefore = "hasLaunchedBefore"
    }

    // MARK: - 기본값
    private static let defaultValues: [String: Any] = [
        Keys.updateInterval: 2.0,
        Keys.language: "en-us",
        Keys.notifyOnConnect: true,
        Keys.notifyOnDisconnect: true,
        Keys.notifyDetailedInfo: true,
        Keys.notifySilent: false,
        Keys.showChargingStatus: true,
        Keys.showAdapterWattage: true,
        Keys.showCurrentWattage: true,
        Keys.showVoltage: true,
        Keys.showAmperage: true,
        Keys.showAdapterInfo: true,
        Keys.showBatteryLevel: true,
        Keys.showBatteryHealth: true,
        Keys.showCycleCount: true,
        Keys.showTemperature: true,
        Keys.showTimeRemaining: true,
        Keys.showSystemPower: true
    ]

    // MARK: - 초기화
    private init() {
        let ud = UserDefaults.standard
        ud.register(defaults: AppSettings.defaultValues)

        if !ud.bool(forKey: Keys.hasLaunchedBefore) {
            for (key, value) in AppSettings.defaultValues {
                ud.set(value, forKey: key)
            }
            ud.set(true, forKey: Keys.hasLaunchedBefore)
            ud.synchronize()
        }

        self.updateInterval = ud.double(forKey: Keys.updateInterval)
        self.language = ud.string(forKey: Keys.language) ?? "en-us"
        self.notifyOnConnect = ud.bool(forKey: Keys.notifyOnConnect)
        self.notifyOnDisconnect = ud.bool(forKey: Keys.notifyOnDisconnect)
        self.notifyDetailedInfo = ud.bool(forKey: Keys.notifyDetailedInfo)
        self.notifySilent = ud.bool(forKey: Keys.notifySilent)
        self.showChargingStatus = ud.bool(forKey: Keys.showChargingStatus)
        self.showAdapterWattage = ud.bool(forKey: Keys.showAdapterWattage)
        self.showCurrentWattage = ud.bool(forKey: Keys.showCurrentWattage)
        self.showVoltage = ud.bool(forKey: Keys.showVoltage)
        self.showAmperage = ud.bool(forKey: Keys.showAmperage)
        self.showAdapterInfo = ud.bool(forKey: Keys.showAdapterInfo)
        self.showBatteryLevel = ud.bool(forKey: Keys.showBatteryLevel)
        self.showBatteryHealth = ud.bool(forKey: Keys.showBatteryHealth)
        self.showCycleCount = ud.bool(forKey: Keys.showCycleCount)
        self.showTemperature = ud.bool(forKey: Keys.showTemperature)
        self.showTimeRemaining = ud.bool(forKey: Keys.showTimeRemaining)
        self.showSystemPower = ud.bool(forKey: Keys.showSystemPower)
    }
}
