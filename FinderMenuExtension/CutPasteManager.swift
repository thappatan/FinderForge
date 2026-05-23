import AppKit
import FinderSync

final class CutPasteManager {

    func cut(items: [URL]) {
        guard !items.isEmpty else { return }
        let controller = FIFinderSyncController.default()

        // เคลียร์ badge ของ cut item เก่า
        for path in SharedSettings.loadCutItems() {
            controller.setBadgeIdentifier("", for: URL(fileURLWithPath: path))
        }

        // บันทึก state ใหม่
        SharedSettings.saveCutItems(items.map { $0.path })

        // ใส่ badge
        for url in items {
            controller.setBadgeIdentifier("cut", for: url)
        }

        // เผื่อ user ใช้ Cmd+V ใน Finder ปกติ — ให้ทำหน้าที่เป็น copy fallback
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(items as [NSURL])
    }

    func pasteMove(to destination: URL) {
        let cutPaths = SharedSettings.loadCutItems()
        guard !cutPaths.isEmpty else { return }

        let controller = FIFinderSyncController.default()
        var moved: [URL] = []
        var errors: [String] = []

        for path in cutPaths {
            let source = URL(fileURLWithPath: path)

            guard FileManager.default.fileExists(atPath: path) else {
                errors.append("File no longer exists: \(source.lastPathComponent)")
                continue
            }

            // ป้องกัน move เข้าตัวเอง
            if source == destination ||
               destination.path.hasPrefix(source.path + "/") {
                errors.append("Cannot move \(source.lastPathComponent) into itself")
                continue
            }

            let dest = uniqueDestination(for: source, in: destination)

            do {
                try FileManager.default.moveItem(at: source, to: dest)
                moved.append(dest)
                controller.setBadgeIdentifier("", for: source)
            } catch {
                errors.append("\(source.lastPathComponent): \(error.localizedDescription)")
            }
        }

        SharedSettings.clearCutItems()

        if !errors.isEmpty {
            presentErrors(errors)
        }

        if !moved.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSWorkspace.shared.activateFileViewerSelecting(moved)
            }
        }
    }

    func clearCut() {
        let controller = FIFinderSyncController.default()
        for path in SharedSettings.loadCutItems() {
            controller.setBadgeIdentifier("", for: URL(fileURLWithPath: path))
        }
        SharedSettings.clearCutItems()
    }

    // MARK: - Helpers

    private func uniqueDestination(for source: URL, in folder: URL) -> URL {
        let baseName = source.deletingPathExtension().lastPathComponent
        let ext = source.pathExtension

        var candidate = folder.appendingPathComponent(source.lastPathComponent)
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty
                ? "\(baseName) \(counter)"
                : "\(baseName) \(counter).\(ext)"
            candidate = folder.appendingPathComponent(newName)
            counter += 1
        }
        return candidate
    }

    private func presentErrors(_ messages: [String]) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Some items could not be moved", comment: "")
            alert.informativeText = messages.joined(separator: "\n")
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}
