import Foundation
import ZIPFoundation

public struct Sinf: Codable {
    public let id: Int64
    public let data: Data

    public init(id: Int64, data: Data) {
        self.id = id
        self.data = data
    }
}

public protocol ZipProtocol {
    func unzip(at path: String) throws
    func zip(files: [String], to path: String) throws
    func replicateSinf(inputPath: String, outputPath: String, sinfs: [Sinf]) throws
}

public class ZipUtility: ZipProtocol {
    public static let shared = ZipUtility()

    private init() {}

    public func unzip(at path: String) throws {
        guard let archive = Archive(url: URL(fileURLWithPath: path), accessMode: .read) else {
            throw AppStoreError.custom(String(localized: "unable_to_open_zip"))
        }

        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)

        for entry in archive {
            try archive.extract(entry, to: destinationURL.appendingPathComponent(entry.path))
        }
    }

    public func zip(files: [String], to path: String) throws {
        guard let archive = Archive(url: URL(fileURLWithPath: path), accessMode: .create) else {
            throw AppStoreError.custom(String(localized: "unable_to_create_zip"))
        }

        for file in files {
            let fileURL = URL(fileURLWithPath: file)
            try archive.addEntry(with: fileURL.lastPathComponent, relativeTo: fileURL.deletingLastPathComponent())
        }
    }

    public func replicateSinf(inputPath: String, outputPath: String, sinfs: [Sinf]) throws {
        guard let archive = Archive(url: URL(fileURLWithPath: inputPath), accessMode: .read) else {
            throw AppStoreError.custom(String(localized: "unable_to_open_source_zip"))
        }

        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true, attributes: nil)

        for entry in archive {
            try archive.extract(entry, to: temporaryURL.appendingPathComponent(entry.path))
        }

        for sinf in sinfs {
            let sinfPath = temporaryURL.appendingPathComponent("META-INF/sinf_\(sinf.id).sinf")
            try FileManager.default.createDirectory(at: sinfPath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try sinf.data.write(to: sinfPath)
        }

        guard let newArchive = Archive(url: URL(fileURLWithPath: outputPath), accessMode: .create) else {
            throw AppStoreError.custom(String(localized: "unable_to_create_new_zip"))
        }

        let enumerator = FileManager.default.enumerator(at: temporaryURL, includingPropertiesForKeys: [.isDirectoryKey])
        while let fileURL = enumerator?.nextObject() as? URL {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue {
                try newArchive.addEntry(with: fileURL.path.replacingOccurrences(of: temporaryURL.path + "/", with: ""),
                                        relativeTo: temporaryURL)
            }
        }

        try FileManager.default.removeItem(at: temporaryURL)
    }
}
