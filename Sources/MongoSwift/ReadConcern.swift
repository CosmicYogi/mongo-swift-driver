import libmongoc

/// An enumeration of possible ReadConcern levels.
public enum ReadConcernLevel: String {
    case local
    case available
    case majority
    case linearizable
    case snapshot
}

/// A class to represent a MongoDB read concern.
public class ReadConcern: BsonEncodable {

    /// A pointer to a mongoc_read_concern_t
    internal var _readConcern: OpaquePointer?

    /// The level of this readConcern, or nil if the level is not set.
    public var level: String? {
        guard let level = mongoc_read_concern_get_level(self._readConcern) else {
            return nil
        }
        return String(cString: level)
    }

    /// Initialize a new ReadConcern from a ReadConcernLevel.
    public convenience init(_ level: ReadConcernLevel) throws {
        try self.init(level.rawValue)
    }

    /// Initialize a new ReadConcern from a String corresponding to a read concern level.
    public init(_ level: String) throws {
        self._readConcern = mongoc_read_concern_new()
        if !mongoc_read_concern_set_level(self._readConcern, level) {
            throw MongoError.readConcernError(message: "Failed to set read concern level to '\(level)'")
        }
    }

    /// Initialize a new empty ReadConcern.
    public init() {
        self._readConcern = mongoc_read_concern_new()
    }

    /// Initialize a new ReadConcern from a Document.
    public convenience init(_ doc: Document) throws {
        if let level = doc["level"] as? String {
            try self.init(level)
        } else {
            self.init()
        }
    }

    /// Initializes a new ReadConcern by copying a mongoc_read_concern_t.
    /// The caller is responsible for freeing the original mongoc_read_concern_t.
    internal init(_ readConcern: OpaquePointer?) {
        self._readConcern = mongoc_read_concern_copy(readConcern)
    }

    /// Appends this readConcern to a Document.
    internal func append(to doc: Document) throws {
        if !mongoc_read_concern_append(self._readConcern, doc.data) {
            throw MongoError.readConcernError(message: "Error appending readconcern to document \(doc)")
        }
    }

    public func encode(to encoder: BsonEncoder) throws {
        try encoder.encode(self.level, forKey: "level")
    }

    deinit {
        guard let readConcern = self._readConcern else { return }
        mongoc_read_concern_destroy(readConcern)
        self._readConcern = nil
    }

}
