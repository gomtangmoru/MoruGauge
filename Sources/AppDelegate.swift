import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var powerMonitor: PowerMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 설정 초기화 (첫 실행 시 기본값 영구 저장)
        _ = AppSettings.shared

        // 2. 로컬라이제이션 초기화
        LocalizationManager.shared.initialize()

        // 3. 알림 권한 요청
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
            print("알림 권한: \(granted ? "허용" : "거부")")
        }

        // 4. PowerMonitor 초기화 및 시작 (StatusBarController보다 먼저!)
        powerMonitor = PowerMonitor()
        powerMonitor?.startMonitoring()

        // 5. StatusBarController 초기화 (이미 데이터가 준비된 상태)
        statusBarController = StatusBarController(powerMonitor: powerMonitor!)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
