import CloudKit
import Foundation
@testable import HeimdallServices
import Testing

struct SnapshotCloudRecordTests {
    @Test
    func roundTripPreservesFields() throws {
        let zoneID = CKRecordZone.ID(zoneName: "heimdall-sync-space", ownerName: CKCurrentUserDefaultName)
        let source = SnapshotCloudRecord(
            installationID: "installation-1",
            sourceDevice: "studio",
            publishedAt: "2026-04-24T10:00:00Z",
            payload: Data("{\"kind\":\"synced-installation\"}".utf8),
            contractVersion: 3
        )

        let ckRecord = source.toCKRecord(zoneID: zoneID)

        #expect(ckRecord.recordType == SnapshotCloudRecord.recordType)
        #expect(ckRecord.recordID.recordName == "installation-1")
        #expect(ckRecord[SnapshotCloudRecord.Field.installationID] as? String == "installation-1")
        #expect(ckRecord[SnapshotCloudRecord.Field.sourceDevice] as? String == "studio")
        #expect(ckRecord[SnapshotCloudRecord.Field.publishedAt] as? String == "2026-04-24T10:00:00Z")

        let decoded = try #require(SnapshotCloudRecord.from(ckRecord: ckRecord))
        #expect(decoded.installationID == source.installationID)
        #expect(decoded.sourceDevice == source.sourceDevice)
        #expect(decoded.publishedAt == source.publishedAt)
        #expect(decoded.payload == source.payload)
        #expect(decoded.contractVersion == source.contractVersion)
        #expect(decoded.systemFieldsData != nil)
    }

    @Test
    func decodesLegacyPlainPayloadField() throws {
        let zoneID = CKRecordZone.ID(zoneName: "heimdall-sync-space", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "installation-legacy", zoneID: zoneID)
        let record = CKRecord(recordType: SnapshotCloudRecord.recordType, recordID: recordID)
        let payload = Data("{\"legacy\":true}".utf8)
        record[SnapshotCloudRecord.Field.installationID] = "installation-legacy" as CKRecordValue
        record[SnapshotCloudRecord.Field.sourceDevice] = "mac-mini" as CKRecordValue
        record[SnapshotCloudRecord.Field.publishedAt] = "2026-04-01T09:00:00Z" as CKRecordValue
        record[SnapshotCloudRecord.Field.payload] = payload as CKRecordValue

        let decoded = try #require(SnapshotCloudRecord.from(ckRecord: record))
        #expect(decoded.payload == payload)
        #expect(decoded.installationID == "installation-legacy")
    }

    @Test
    func returnsNilWhenRequiredMetadataMissing() {
        let zoneID = CKRecordZone.ID(zoneName: "heimdall-sync-space", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "incomplete", zoneID: zoneID)
        let record = CKRecord(recordType: SnapshotCloudRecord.recordType, recordID: recordID)
        record[SnapshotCloudRecord.Field.installationID] = "incomplete" as CKRecordValue
        // sourceDevice and publishedAt missing
        record[SnapshotCloudRecord.Field.payload] = Data() as CKRecordValue

        #expect(SnapshotCloudRecord.from(ckRecord: record) == nil)
    }

    @Test
    func systemFieldsRoundTripPreservesRecordID() throws {
        let zoneID = CKRecordZone.ID(zoneName: "heimdall-sync-space", ownerName: CKCurrentUserDefaultName)
        let originalID = CKRecord.ID(recordName: "installation-42", zoneID: zoneID)
        let original = CKRecord(recordType: SnapshotCloudRecord.recordType, recordID: originalID)
        original[SnapshotCloudRecord.Field.installationID] = "installation-42" as CKRecordValue
        original[SnapshotCloudRecord.Field.sourceDevice] = "mac" as CKRecordValue
        original[SnapshotCloudRecord.Field.publishedAt] = "2026-04-24T10:00:00Z" as CKRecordValue

        let encoded = SnapshotCloudRecord.encodeSystemFields(of: original)
        let restored = try #require(SnapshotCloudRecord.decodeSystemFields(encoded))
        #expect(restored.recordID == originalID)
        #expect(restored.recordType == SnapshotCloudRecord.recordType)
    }
}
