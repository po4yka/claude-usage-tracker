import CloudKit
import Foundation

public struct SnapshotCloudRecord: Sendable, Equatable {
    public static let recordType: CKRecord.RecordType = "SyncedInstallationSnapshot"

    public var installationID: String
    public var sourceDevice: String
    public var publishedAt: String
    public var payload: Data
    public var contractVersion: Int?
    public var systemFieldsData: Data?

    public init(
        installationID: String,
        sourceDevice: String,
        publishedAt: String,
        payload: Data,
        contractVersion: Int? = nil,
        systemFieldsData: Data? = nil
    ) {
        self.installationID = installationID
        self.sourceDevice = sourceDevice
        self.publishedAt = publishedAt
        self.payload = payload
        self.contractVersion = contractVersion
        self.systemFieldsData = systemFieldsData
    }

    public enum Field {
        public static let installationID = "installationID"
        public static let sourceDevice = "sourceDevice"
        public static let publishedAt = "publishedAt"
        public static let payload = "payload"
        public static let contractVersion = "contractVersion"
    }

    public func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let record = self.restoredSystemFieldsRecord()
            ?? CKRecord(
                recordType: Self.recordType,
                recordID: CKRecord.ID(recordName: self.installationID, zoneID: zoneID)
            )
        record[Field.installationID] = self.installationID as CKRecordValue
        record[Field.sourceDevice] = self.sourceDevice as CKRecordValue
        record[Field.publishedAt] = self.publishedAt as CKRecordValue
        record.encryptedValues[Field.payload] = self.payload as CKRecordValue
        if let contractVersion = self.contractVersion {
            record[Field.contractVersion] = NSNumber(value: contractVersion)
        }
        return record
    }

    public static func from(ckRecord record: CKRecord) -> SnapshotCloudRecord? {
        guard
            let installationID = record[Field.installationID] as? String,
            let sourceDevice = record[Field.sourceDevice] as? String,
            let publishedAt = record[Field.publishedAt] as? String
        else {
            return nil
        }
        let payload: Data
        if let encrypted = record.encryptedValues[Field.payload] as? Data {
            payload = encrypted
        } else if let plain = record[Field.payload] as? Data {
            payload = plain
        } else {
            return nil
        }
        let contractVersion = (record[Field.contractVersion] as? NSNumber)?.intValue
        return SnapshotCloudRecord(
            installationID: installationID,
            sourceDevice: sourceDevice,
            publishedAt: publishedAt,
            payload: payload,
            contractVersion: contractVersion,
            systemFieldsData: Self.encodeSystemFields(of: record)
        )
    }

    private func restoredSystemFieldsRecord() -> CKRecord? {
        guard let systemFieldsData = self.systemFieldsData else { return nil }
        return Self.decodeSystemFields(systemFieldsData)
    }

    public static func encodeSystemFields(of record: CKRecord) -> Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }

    public static func decodeSystemFields(_ data: Data) -> CKRecord? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
            return nil
        }
        unarchiver.requiresSecureCoding = true
        return CKRecord(coder: unarchiver)
    }
}
