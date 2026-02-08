import Foundation
import IOKit.ps
import UserNotifications

class PowerMonitor {
    // MARK: - 전력 상태 프로퍼티
    private(set) var isCharging: Bool = false
    private(set) var externalConnected: Bool = false
    private(set) var currentWattage: Double = 0
    private(set) var voltage: Double = 0
    private(set) var amperage: Double = 0
    private(set) var adapterWattage: Int = 0
    private(set) var batteryLevel: Int = 0
    private(set) var batteryHealth: Int = 0
    private(set) var cycleCount: Int = 0
    private(set) var temperature: Double = 0
    private(set) var timeToFull: Int = -1
    private(set) var timeToEmpty: Int = -1
    private(set) var adapterName: String = ""
    private(set) var adapterVoltage: Double = 0
    private(set) var adapterAmperage: Double = 0
    private(set) var systemPower: Double = 0
    private(set) var isSystemPowerAvailable: Bool = false
    private(set) var isSystemPowerEstimate: Bool = false

    // MARK: - 내부 상태
    private var isFirstUpdate: Bool = true
    private var runLoopSource: CFRunLoopSource?
    private var detailedNotificationWork: DispatchWorkItem?

    // MARK: - 모니터링 시작
    func startMonitoring() {
        updatePowerInfo()
        isFirstUpdate = false
        setupPowerSourceCallback()
    }

    // MARK: - 전력 정보 업데이트
    func updatePowerInfo() {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault, IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return }

        let wasExternalConnected = externalConnected

        isCharging = dict["IsCharging"] as? Bool ?? false
        externalConnected = dict["ExternalConnected"] as? Bool ?? false

        if let v = dict["Voltage"] as? Int { voltage = Double(v) / 1000.0 }

        var rawAmperage: Int = 0
        if let a = dict["Amperage"] as? Int {
            rawAmperage = a
            amperage = Double(abs(a)) / 1000.0
        }
        currentWattage = voltage * amperage

        // 배터리 레벨
        let maxCap = dict["MaxCapacity"] as? Int ?? 0
        let curCap = dict["CurrentCapacity"] as? Int ?? 0
        if maxCap > 0 { batteryLevel = (curCap * 100) / maxCap }

        // 배터리 건강도 (AppleRawMaxCapacity 우선)
        let designCap = dict["DesignCapacity"] as? Int ?? 0
        if designCap > 0 {
            if let rawMax = dict["AppleRawMaxCapacity"] as? Int, rawMax > 0 {
                batteryHealth = (rawMax * 100) / designCap
            } else if maxCap > 0 {
                let ratio = (maxCap * 100) / designCap
                batteryHealth = (ratio > 10 && ratio <= 120) ? ratio : maxCap
            }
        }

        if let c = dict["CycleCount"] as? Int { cycleCount = c }
        if let t = dict["Temperature"] as? Int { temperature = Double(t) / 100.0 }

        // 남은 시간
        timeToFull = -1; timeToEmpty = -1
        if let ttf = dict["AvgTimeToFull"] as? Int, isCharging, ttf > 0, ttf < 65535 { timeToFull = ttf }
        if let tte = dict["AvgTimeToEmpty"] as? Int, !isCharging, !externalConnected, tte > 0, tte < 65535 { timeToEmpty = tte }
        if let tr = dict["TimeRemaining"] as? Int, tr > 0, tr < 65535 {
            if isCharging && timeToFull < 0 { timeToFull = tr }
            else if !isCharging && !externalConnected && timeToEmpty < 0 { timeToEmpty = tr }
        }

        // 충전기 정보
        adapterWattage = 0; adapterName = ""; adapterVoltage = 0; adapterAmperage = 0
        if let details = dict["AppleRawAdapterDetails"] as? [[String: Any]] {
            for ad in details {
                if let w = ad["Watts"] as? Int, w > adapterWattage { adapterWattage = w }
                if let d = ad["Description"] as? String, !d.isEmpty { adapterName = d }
                if let av = ad["Voltage"] as? Int, av > 0 { adapterVoltage = Double(av) / 1000.0 }
                if let aa = ad["Current"] as? Int, aa > 0 { adapterAmperage = Double(aa) / 1000.0 }
            }
        }
        if adapterVoltage == 0 && adapterWattage > 0 && adapterAmperage > 0 {
            adapterVoltage = Double(adapterWattage) / adapterAmperage
        }
        if adapterWattage == 0, let ai = dict["AdapterInfo"] as? Int {
            let w = ai & 0xFFFF; if w > 0 && w < 500 { adapterWattage = w }
        }

        calculateSystemPower(rawAmperage: rawAmperage)

        // MARK: - 충전기 상태 변경 → 알림
        if !isFirstUpdate && externalConnected != wasExternalConnected {
            let settings = AppSettings.shared

            if externalConnected {
                detailedNotificationWork?.cancel()

                if settings.notifyOnConnect {
                    // Phase 1: 즉시 "충전기 연결됨" 알림
                    sendImmediateConnectNotification()

                    // Phase 2: 2초 후 상세 정보 알림 (설정에서 켜진 경우)
                    if settings.notifyDetailedInfo {
                        scheduleDetailedNotification()
                    }
                }
            } else {
                detailedNotificationWork?.cancel()
                if settings.notifyOnDisconnect {
                    sendDisconnectNotification()
                }
            }
        }
    }

    // MARK: - 시스템 전력 계산
    private func calculateSystemPower(rawAmperage: Int) {
        if !externalConnected {
            let sp = voltage * amperage
            // Apple Silicon에서 배터리 Amperage 값이 부정확할 수 있음
            // 노트북 최소 소비 전력(~2W) 미만이면 표시하지 않음
            if sp >= 2.0 {
                systemPower = sp
                isSystemPowerAvailable = true
                isSystemPowerEstimate = false
            } else {
                systemPower = 0
                isSystemPowerAvailable = false
                isSystemPowerEstimate = false
            }
        } else if isCharging {
            if adapterVoltage > 0 && adapterAmperage > 0 {
                systemPower = max(0, adapterVoltage * adapterAmperage - currentWattage)
                isSystemPowerAvailable = true; isSystemPowerEstimate = true
            } else if adapterWattage > 0 {
                systemPower = max(0, Double(adapterWattage) - currentWattage)
                isSystemPowerAvailable = true; isSystemPowerEstimate = true
            } else {
                systemPower = 0; isSystemPowerAvailable = false; isSystemPowerEstimate = false
            }
        } else {
            systemPower = 0; isSystemPowerAvailable = false; isSystemPowerEstimate = false
        }
    }

    // MARK: - Phase 1: 즉시 연결 알림
    private func sendImmediateConnectNotification() {
        let l = LocalizationManager.shared
        sendNotification(
            title: l.get("notification.connected_title"),
            body: l.get("notification.connected_body")
        )
    }

    // MARK: - Phase 2: 지연 상세 정보 알림
    private func scheduleDetailedNotification() {
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.externalConnected else { return }
            // 최신 데이터로 재읽기
            self.updatePowerInfoSilent()
            self.sendDetailedInfoNotification()
        }
        detailedNotificationWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }

    /// 알림 트리거 없이 데이터만 업데이트
    private func updatePowerInfoSilent() {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault, IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return }

        // 어댑터 정보만 갱신
        if let details = dict["AppleRawAdapterDetails"] as? [[String: Any]] {
            for ad in details {
                if let w = ad["Watts"] as? Int, w > adapterWattage { adapterWattage = w }
                if let d = ad["Description"] as? String, !d.isEmpty { adapterName = d }
                if let av = ad["Voltage"] as? Int, av > 0 { adapterVoltage = Double(av) / 1000.0 }
                if let aa = ad["Current"] as? Int, aa > 0 { adapterAmperage = Double(aa) / 1000.0 }
            }
        }
        if adapterVoltage == 0 && adapterWattage > 0 && adapterAmperage > 0 {
            adapterVoltage = Double(adapterWattage) / adapterAmperage
        }
    }

    private func sendDetailedInfoNotification() {
        let l = LocalizationManager.shared
        let title = l.get("notification.detail_title")

        let v = adapterVoltage > 0 ? adapterVoltage : voltage
        let a = adapterAmperage > 0 ? adapterAmperage : amperage

        let body: String
        if adapterWattage > 0 && v > 0 && a > 0 {
            body = l.format("notification.detail_wva_format", adapterWattage, v, a)
        } else if adapterWattage > 0 {
            body = l.format("notification.detail_w_format", adapterWattage)
        } else {
            return // 정보 없으면 보내지 않음
        }

        sendNotification(title: title, body: body)
    }

    // MARK: - 분리 알림
    private func sendDisconnectNotification() {
        let l = LocalizationManager.shared
        sendNotification(
            title: l.get("notification.disconnected_title"),
            body: l.get("notification.disconnected_body")
        )
    }

    // MARK: - 알림 전송 (UNUserNotification 우선, osascript 폴백)
    private func sendNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                // UNUserNotificationCenter 사용
                self?.deliverUNNotification(center: center, title: title, body: body)
            } else {
                // 권한 없음 → osascript 폴백 (서명 없는 앱에서도 동작)
                print("⚠️ UN 알림 권한 없음 (status=\(settings.authorizationStatus.rawValue)), osascript 폴백 사용")
                self?.deliverOSAScriptNotification(title: title, body: body)
            }
        }
    }

    private func deliverUNNotification(center: UNUserNotificationCenter, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = AppSettings.shared.notifySilent ? nil : .default

        let request = UNNotificationRequest(
            identifier: "mpa-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request) { [weak self] error in
            if let error = error {
                print("❌ UN 알림 실패: \(error.localizedDescription), osascript 폴백")
                self?.deliverOSAScriptNotification(title: title, body: body)
            } else {
                print("✅ UN 알림: \(title) — \(body)")
            }
        }
    }

    /// osascript를 이용한 알림 (서명/권한 불필요, 항상 동작)
    private func deliverOSAScriptNotification(title: String, body: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let t = title.replacingOccurrences(of: "\\", with: "\\\\")
                         .replacingOccurrences(of: "\"", with: "\\\"")
            let b = body.replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "\"", with: "\\\"")
                        .replacingOccurrences(of: "\n", with: " ")
            let silent = AppSettings.shared.notifySilent
            let script = silent
                ? "display notification \"\(b)\" with title \"\(t)\""
                : "display notification \"\(b)\" with title \"\(t)\" sound name \"default\""
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            proc.arguments = ["-e", script]
            proc.standardOutput = nil
            proc.standardError = nil
            do {
                try proc.run()
                proc.waitUntilExit()
                print("✅ OSA 알림: \(title) — \(body)")
            } catch {
                print("❌ OSA 알림 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - IOKit 콜백
    private func setupPowerSourceCallback() {
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        let cb: IOPowerSourceCallbackType = { ctx in
            guard let ctx = ctx else { return }
            let m = Unmanaged<PowerMonitor>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async { m.updatePowerInfo() }
        }
        if let src = IOPSNotificationCreateRunLoopSource(cb, ctx) {
            runLoopSource = src.takeRetainedValue()
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
    }

    deinit {
        detailedNotificationWork?.cancel()
        if let s = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), s, .defaultMode) }
    }
}
