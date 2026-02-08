import Cocoa
import Combine

class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let powerMonitor: PowerMonitor
    private var updateTimer: Timer?
    private var liveUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let settingsWindowController = SettingsWindowController()

    // MARK: - 재사용 메뉴 아이템 (메뉴에 동적으로 추가/제거)
    private let statusLine1 = NSMenuItem()
    private let statusLine2 = NSMenuItem()
    private let adapterMaxItem = NSMenuItem()
    private let currentPowerItem = NSMenuItem()
    private let voltageItem = NSMenuItem()
    private let amperageItem = NSMenuItem()
    private let adapterInfoItem = NSMenuItem()
    private let batteryLevelItem = NSMenuItem()
    private let batteryHealthItem = NSMenuItem()
    private let cycleCountItem = NSMenuItem()
    private let temperatureItem = NSMenuItem()
    private let timeRemainingItem = NSMenuItem()
    private let systemPowerItem = NSMenuItem()
    private let settingsMenuItem = NSMenuItem()
    private let quitMenuItem = NSMenuItem()

    // 마지막으로 메뉴를 구성한 상태 (구조 변경 필요 여부 판단)
    private var lastMenuChargingState: Bool? = nil

    // MARK: - 초기화
    init(powerMonitor: PowerMonitor) {
        self.powerMonitor = powerMonitor
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu

        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.imagePosition = .imageLeading
        }

        // 액션 아이템 설정 (한 번만)
        settingsMenuItem.target = self
        settingsMenuItem.action = #selector(openSettings)
        settingsMenuItem.keyEquivalent = ","

        quitMenuItem.target = self
        quitMenuItem.action = #selector(quit)
        quitMenuItem.keyEquivalent = "q"

        rebuildMenu()
        updateMenuTitles()
        updateStatusBarIcon()
        startBackgroundTimer()
        observeSettings()
    }

    // MARK: - 메뉴 구조 재구성 (아이템 제거/추가, hidden 사용 안 함)
    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        let s = AppSettings.shared
        let connected = powerMonitor.externalConnected

        // 모든 정보 아이템 비활성화 (회색 표시, 클릭 불가)
        let infoItems = [statusLine1, statusLine2, adapterMaxItem, currentPowerItem,
                         voltageItem, amperageItem, adapterInfoItem, batteryLevelItem,
                         batteryHealthItem, cycleCountItem, temperatureItem,
                         timeRemainingItem, systemPowerItem]
        for item in infoItems { item.isEnabled = false }

        // ── 상태 ──
        menu.addItem(statusLine1)

        // ── 충전 섹션 (충전기 연결 시에만) ──
        if connected {
            if s.showChargingStatus { menu.addItem(statusLine2) }
            addSeparator(menu)
            if s.showAdapterWattage { menu.addItem(adapterMaxItem) }
            if s.showCurrentWattage { menu.addItem(currentPowerItem) }
            if s.showVoltage { menu.addItem(voltageItem) }
            if s.showAmperage { menu.addItem(amperageItem) }
            if s.showAdapterInfo { menu.addItem(adapterInfoItem) }
        }

        // ── 배터리 섹션 (항상) ──
        addSeparator(menu)
        if s.showBatteryLevel { menu.addItem(batteryLevelItem) }
        if s.showBatteryHealth { menu.addItem(batteryHealthItem) }
        if s.showCycleCount { menu.addItem(cycleCountItem) }
        if s.showTemperature { menu.addItem(temperatureItem) }
        if s.showTimeRemaining { menu.addItem(timeRemainingItem) }

        // ── 시스템 전력 ──
        if s.showSystemPower {
            addSeparator(menu)
            menu.addItem(systemPowerItem)
        }

        // ── 액션 ──
        addSeparator(menu)
        menu.addItem(settingsMenuItem)
        menu.addItem(quitMenuItem)

        lastMenuChargingState = connected
    }

    /// 연속 구분선 방지: 마지막 아이템이 구분선이 아닐 때만 추가
    private func addSeparator(_ menu: NSMenu) {
        if let last = menu.items.last, !last.isSeparatorItem {
            menu.addItem(NSMenuItem.separator())
        }
    }

    // MARK: - 메뉴 아이템 타이틀만 업데이트 (구조 변경 없음)
    private func updateMenuTitles() {
        let l = LocalizationManager.shared
        let p = powerMonitor

        // 상태
        statusLine1.title = p.externalConnected
            ? l.get("menu.charger_connected")
            : l.get("menu.on_battery")

        // 충전 상태
        if p.isCharging {
            statusLine2.title = l.get("menu.charging")
        } else if p.batteryLevel >= 95 {
            statusLine2.title = l.get("menu.fully_charged")
        } else {
            statusLine2.title = l.get("menu.not_charging")
        }

        // 충전 정보 (연결 시 값 표시, 미연결 시 "--")
        adapterMaxItem.title = p.adapterWattage > 0
            ? l.format("menu.adapter_max_format", p.adapterWattage)
            : l.get("menu.adapter_max_na")

        currentPowerItem.title = p.externalConnected
            ? l.format("menu.current_charging_format", p.currentWattage)
            : l.get("menu.current_charging_na")

        voltageItem.title = p.externalConnected
            ? l.format("menu.voltage_format", p.voltage)
            : l.get("menu.voltage_na")

        amperageItem.title = p.externalConnected
            ? l.format("menu.amperage_format", p.amperage)
            : l.get("menu.amperage_na")

        if p.externalConnected && (!p.adapterName.isEmpty || p.adapterVoltage > 0 || p.adapterAmperage > 0) {
            var info = l.get("menu.adapter_info")
            if !p.adapterName.isEmpty { info += " \(p.adapterName)" }
            if p.adapterVoltage > 0 { info += String(format: " %.1fV", p.adapterVoltage) }
            if p.adapterAmperage > 0 { info += String(format: " %.1fA", p.adapterAmperage) }
            adapterInfoItem.title = info
        } else {
            adapterInfoItem.title = l.get("menu.adapter_info_na")
        }

        // 배터리 정보
        batteryLevelItem.title = l.format("menu.battery_format", p.batteryLevel)

        batteryHealthItem.title = p.batteryHealth > 0
            ? l.format("menu.health_format", p.batteryHealth)
            : l.get("menu.health_na")

        cycleCountItem.title = p.cycleCount > 0
            ? l.format("menu.cycles_format", p.cycleCount)
            : l.get("menu.cycles_na")

        temperatureItem.title = p.temperature > 0
            ? l.format("menu.temperature_format", p.temperature)
            : l.get("menu.temperature_na")

        // 남은 시간
        if p.isCharging && p.timeToFull > 0 {
            let h = p.timeToFull / 60, m = p.timeToFull % 60
            timeRemainingItem.title = h > 0
                ? l.format("menu.time_full_hm_format", h, m)
                : l.format("menu.time_full_m_format", m)
        } else if !p.externalConnected && p.timeToEmpty > 0 {
            let h = p.timeToEmpty / 60, m = p.timeToEmpty % 60
            timeRemainingItem.title = h > 0
                ? l.format("menu.time_left_hm_format", h, m)
                : l.format("menu.time_left_m_format", m)
        } else {
            timeRemainingItem.title = l.get("menu.time_remaining_na")
        }

        // 시스템 전력
        if p.isSystemPowerAvailable {
            let key = p.isSystemPowerEstimate ? "menu.system_power_est_format" : "menu.system_power_format"
            systemPowerItem.title = l.format(key, p.systemPower)
        } else {
            systemPowerItem.title = l.get("menu.system_power_na")
        }

        // 액션
        settingsMenuItem.title = l.get("menu.settings")
        quitMenuItem.title = l.get("menu.quit")
    }

    // MARK: - 메뉴바 아이콘
    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }
        let l = LocalizationManager.shared

        if powerMonitor.externalConnected {
            button.title = l.format("menubar.charging_format", powerMonitor.currentWattage)
            let img = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Charging")
            button.image = img?.withSymbolConfiguration(.init(paletteColors: [.systemGreen]))
        } else {
            button.title = ""
            let img = NSImage(systemSymbolName: "bolt.slash", accessibilityDescription: "Not Charging")
            button.image = img?.withSymbolConfiguration(.init(paletteColors: [.secondaryLabelColor]))
        }
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        powerMonitor.updatePowerInfo()
        // 충전 상태 변경 시 구조 재구성, 아니면 타이틀만 갱신
        if lastMenuChargingState != powerMonitor.externalConnected {
            rebuildMenu()
        }
        updateMenuTitles()
    }

    func menuWillOpen(_ menu: NSMenu) {
        liveUpdateTimer?.invalidate()
        let interval = AppSettings.shared.updateInterval
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.powerMonitor.updatePowerInfo()
            // 충전 상태 바뀌면 구조 재구성
            if self.lastMenuChargingState != self.powerMonitor.externalConnected {
                self.rebuildMenu()
            }
            self.updateMenuTitles()
            self.updateStatusBarIcon()
        }
        RunLoop.main.add(timer, forMode: .common)
        liveUpdateTimer = timer
    }

    func menuDidClose(_ menu: NSMenu) {
        liveUpdateTimer?.invalidate()
        liveUpdateTimer = nil
    }

    // MARK: - 백그라운드 타이머
    private func startBackgroundTimer() {
        updateTimer?.invalidate()
        let interval = AppSettings.shared.updateInterval
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.powerMonitor.updatePowerInfo()
            self?.updateStatusBarIcon()
        }
    }

    private func observeSettings() {
        AppSettings.shared.$updateInterval
            .dropFirst().removeDuplicates()
            .sink { [weak self] _ in self?.startBackgroundTimer() }
            .store(in: &cancellables)
    }

    @objc private func openSettings() { settingsWindowController.show() }
    @objc private func quit() { NSApplication.shared.terminate(nil) }

    deinit {
        updateTimer?.invalidate()
        liveUpdateTimer?.invalidate()
    }
}
