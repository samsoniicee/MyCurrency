import SwiftUI

@main
struct MyCurrencyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Label("MyCurrency Beta", systemImage: "dollarsign.circle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: – Single-instance via DistributedNotificationCenter
//
// On launch, post our PID. Any already-running instance receives it,
// sees pid ≠ own pid, and quits. We ignore our own notification.

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let notifName = Notification.Name("com.niicee.MyCurrency.launched")
    private let myPID = ProcessInfo.processInfo.processIdentifier

    func applicationDidFinishLaunching(_ notification: Notification) {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self,
                        selector: #selector(peerLaunched(_:)),
                        name: Self.notifName,
                        object: nil)
        dnc.postNotificationName(Self.notifName,
                                 object: "\(myPID)",
                                 userInfo: nil,
                                 deliverImmediately: true)
    }

    @objc private func peerLaunched(_ n: Notification) {
        guard let s = n.object as? String,
              let pid = pid_t(s),
              pid != myPID else { return }
        // A different instance just launched — we are the old one, quit.
        NSApplication.shared.terminate(nil)
    }
}
