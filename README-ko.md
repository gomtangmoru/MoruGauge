# ⚡ MoruGauge (모루게이지)

macOS 메뉴바에서 충전기와 배터리를 실시간으로 모니터링하는 경량 앱입니다.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

> 🇺🇸 [English README](README.md)

---

## 기능

### 🔌 충전기 감지 및 알림
- 충전기 연결/분리 시 즉시 알림
- USB-PD 협상 완료 후 **W / V / A** 상세 정보 후속 알림
- 연결 알림, 분리 알림, 상세 정보 알림을 각각 ON/OFF 가능
- 무음 모드 지원

### 📊 실시간 메뉴바 모니터링
- 메뉴바 아이콘 옆에 현재 충전 W 표시
- 클릭하면 상세 전력 정보 확인:

**충전 중:**
| 항목 | 예시 |
|------|------|
| 충전 상태 | ⚡ 충전 중 / ⏸️ 충전 대기 중 / ✅ 완충됨 |
| 충전기 최대 | 96W |
| 현재 충전 | 45.2W |
| 전압 | 20.15V |
| 전류 | 2.24A |
| 충전기 정보 | USB-C 20.0V 3.0A |
| 시스템 소비 | ~12.5W (추정) |

**배터리 사용 중:**
| 항목 | 예시 |
|------|------|
| 배터리 잔량 | 78% |
| 배터리 건강 | 87% |
| 충전 사이클 | 446회 |
| 온도 | 30.8°C |
| 남은 시간 | 7시간 11분 |
| 시스템 소비 | 8.3W |

- **메뉴를 열어놓은 상태에서도** 값이 실시간으로 갱신됩니다
- 표시할 수 없는 값은 `--`로 표기

### ⚙️ 설정
- **업데이트 주기**: 1~30초
- **메뉴 항목 개별 ON/OFF** (충전 정보 / 배터리 정보 섹션별)
- **알림 설정**: 연결, 분리, 상세 정보, 무음 각각 제어

### 🌐 다국어 지원 (JSON 기반)
- 기본 내장: **English**, **한국어**, **한국어 (냥냥체) 🐱**
- Locales 폴더에 `.json` 파일을 추가하면 새 언어 지원
- 앱 업데이트 시 기존 번역 보존 — 새 키만 자동 머지

---

## 설치

### 소스에서 빌드

**요구사항:** macOS 13 이상, Xcode Command Line Tools

```bash
git clone https://github.com/YOUR_USERNAME/morugauge.git
cd morugauge
chmod +x build.sh
bash build.sh
```

빌드된 앱은 `build/morugauge.app`에 생성됩니다.

### 실행

```bash
open build/morugauge.app
```

또는 `morugauge.app`을 Applications 폴더로 드래그하세요.

> 이 앱은 메뉴바에서만 동작합니다 (Dock 아이콘 없음).

---

## 작동 원리

모루게이지는 macOS의 **IOKit** 프레임워크(`AppleSmartBattery` 서비스)에서 직접 전력 데이터를 읽습니다:

- 배터리 전압, 전류, 용량, 건강도, 사이클, 온도
- `AppleRawAdapterDetails`를 통한 충전기 상세 정보 (W, V, A)
- `IOPSNotificationCreateRunLoopSource`를 통한 전원 변경 이벤트 감지

**시스템 전력 추정:**
- 배터리 사용 시: `전압 × 전류`로 계산 (2W 이상일 때 표시)
- 충전 중: `어댑터 출력 − 배터리 충전 전력`으로 추정

---

## 번역 추가하기

1. **설정 → 번역 → 번역 폴더 열기** 클릭
   - 또는 `~/Library/Application Support/morugauge/Locales/`로 이동
2. 기존 `.json` 파일(예: `en-us.json`)을 복사하고 이름 변경 (예: `ja-jp.json`)
3. 값만 번역 (키는 그대로 유지)
4. 앱 재시작 → 설정에 새 언어 표시

예시 구조:
```json
{
    "language.name": "日本語",
    "menu.charger_connected": "🔌 充電器接続済み",
    "menu.charging": "⚡ 充電中",
    ...
}
```

---

## 프로젝트 구조

```
morugauge/
├── Sources/
│   ├── main.swift                 # 앱 진입점
│   ├── AppDelegate.swift          # 생명주기 및 알림 권한
│   ├── Settings.swift             # UserDefaults 기반 설정 모델
│   ├── LocalizationManager.swift  # JSON 기반 다국어 시스템
│   ├── PowerMonitor.swift         # IOKit 전력 모니터링 + 알림
│   ├── StatusBarController.swift  # 메뉴바 UI 관리
│   └── SettingsWindow.swift       # SwiftUI 설정 창
├── Resources/
│   ├── Info.plist                 # 앱 번들 설정
│   └── Locales/
│       ├── en-us.json             # English
│       ├── ko-kr.json             # 한국어
│       └── ko-nyang.json          # 한국어 (냥냥체 🐱)
├── Package.swift                  # Swift Package Manager 설정
└── build.sh                       # 빌드 및 번들 스크립트
```

---

## 라이선스

MIT License — 자유롭게 사용, 수정, 배포하세요.

---

## 감사

이 프로젝트는 AI(Claude)와 함께 **바이브 코딩**으로 처음부터 끝까지 제작되었습니다.

Swift, AppKit, SwiftUI, IOKit으로 제작되었습니다.

