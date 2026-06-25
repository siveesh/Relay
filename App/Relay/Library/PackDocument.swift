import SwiftUI
import UniformTypeIdentifiers

/// A `FileDocument` wrapper used by `fileExporter` to write a command pack to disk.
///
/// The JSON is produced on the main actor by the view and handed in as `Data`, so this type
/// stays a simple, isolation-free container.
struct PackDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
