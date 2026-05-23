import AppKit
import OSLog

final class FileCreator {

    func create(template: FileTemplate, in folder: URL) {
        let fileName = uniqueFileName(for: template, in: folder)
        let fileURL = folder.appendingPathComponent(fileName)

        let content = expandVariables(template.templateContent ?? "",
                                       fileURL: fileURL)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            extLog.debug("FileCreator: wrote \(fileURL.path, privacy: .public)")
        } catch {
            extLog.error("FileCreator: failed to write \(fileURL.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return
        }

        // chmod +x สำหรับ script files
        if ["sh", "py", "rb", "pl"].contains(template.ext) {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: fileURL.path
            )
        }

        // เลือกไฟล์ใน Finder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }

    // MARK: - File Naming

    private func uniqueFileName(for template: FileTemplate, in folder: URL) -> String {
        let base = expandVariables(template.baseName, fileURL: folder)
        let ext = template.ext

        var candidate = "\(base).\(ext)"
        var counter = 2

        while FileManager.default.fileExists(
            atPath: folder.appendingPathComponent(candidate).path
        ) {
            candidate = "\(base) \(counter).\(ext)"
            counter += 1
        }
        return candidate
    }

    // MARK: - Template Variables

    private func expandVariables(_ template: String, fileURL: URL) -> String {
        var result = template

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let dateTimeFmt = ISO8601DateFormatter()

        let now = Date()
        let folder = fileURL.deletingLastPathComponent().lastPathComponent

        let replacements: [String: String] = [
            "{date}":     dateFmt.string(from: now),
            "{time}":     timeFmt.string(from: now),
            "{datetime}": dateTimeFmt.string(from: now),
            "{user}":     NSUserName(),
            "{folder}":   folder,
            "{uuid}":     UUID().uuidString,
            "{cursor}":   "",  // currently no-op; future: integrate with editor
        ]

        for (key, value) in replacements {
            result = result.replacingOccurrences(of: key, with: value)
        }
        return result
    }
}
