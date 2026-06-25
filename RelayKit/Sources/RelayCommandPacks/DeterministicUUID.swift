import Foundation
import CryptoKit

extension UUID {
    /// Relay's fixed namespace UUID for deriving stable ids from pack slugs.
    private static let relayNamespace = UUID(uuidString: "B7E6C3A2-1D4F-5E80-9A2B-3C4D5E6F7081")!

    /// Derives a stable RFC 4122 v5 (SHA-1, name-based) UUID from a slug.
    ///
    /// Importing the same pack twice therefore yields the same ids, which lets the importer
    /// de-duplicate and update in place rather than creating duplicates.
    init(namespacedSlug slug: String) {
        var bytes = [UInt8]()
        bytes.reserveCapacity(16)
        withUnsafeBytes(of: UUID.relayNamespace.uuid) { bytes.append(contentsOf: $0) }

        var hasher = Insecure.SHA1()
        hasher.update(data: Data(bytes))
        hasher.update(data: Data(slug.utf8))
        var digest = Array(hasher.finalize())

        // Set version (5) and the RFC 4122 variant bits.
        digest[6] = (digest[6] & 0x0F) | 0x50
        digest[8] = (digest[8] & 0x3F) | 0x80

        let uuidBytes = (
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7],
            digest[8], digest[9], digest[10], digest[11],
            digest[12], digest[13], digest[14], digest[15]
        )
        self.init(uuid: uuidBytes)
    }
}
