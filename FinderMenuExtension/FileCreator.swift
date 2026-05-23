//
//  FileCreator.swift
//  FinderForge
//
//  Copyright (C) 2026 thappatan chanphen
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

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
