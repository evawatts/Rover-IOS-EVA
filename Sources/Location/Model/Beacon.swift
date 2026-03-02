// Copyright (c) 2020-present, Rover Labs, Inc. All rights reserved.
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Rover.
//
// This copyright notice shall be included in all copies or substantial portions of
// the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import CoreData
import CoreLocation
import RoverData
import RoverFoundation
import os.log

public final class Beacon: NSManagedObject {
    @nonobjc @available(*, deprecated, message: "Please use Beacon.beaconFetchRequest() instead.")
    public class func fetchRequest() -> NSFetchRequest<Beacon> {
        return NSFetchRequest<Beacon>(entityName: "Beacon")
    }

    public class func beaconFetchRequest() -> NSFetchRequest<Beacon> {
        return NSFetchRequest<Beacon>(entityName: "Beacon")
    }

    @NSManaged public internal(set) var id: String
    @NSManaged public internal(set) var name: String
    @NSManaged public internal(set) var uuid: UUID
    @NSManaged public internal(set) var major: Int32
    @NSManaged public internal(set) var minor: Int32
    @NSManaged public internal(set) var tags: [String]

    @NSManaged public private(set) var regionIdentifier: String

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        self.tags = []
    }

    override public func willSave() {
        if self.regionIdentifier != self.region.identifier {
            self.regionIdentifier = self.region.identifier
        }
    }
}

// MARK: Attributes

extension Beacon {
    public var attributes: Attributes {
        return [
            "id": self.id,
            "name": self.name,
            "uuid": self.uuid.uuidString,
            "major": Int(self.major),
            "minor": Int(self.minor),
            "tags": self.tags,
        ]
    }
}

// MARK: Core Location

extension Beacon {
    public var region: CLBeaconRegion {
        return CLBeaconRegion(
            uuid: self.uuid,
            major: UInt16(self.major),
            minor: UInt16(self.minor),
            identifier: "\(self.uuid.uuidString):\(self.major):\(self.minor)"
        )
    }
}

// MARK: Events

extension Beacon {
    public var enterEvent: EventInfo {
        return EventInfo(
            name: "Beacon Entered",
            namespace: "rover",
            attributes: ["beacon": self.attributes]
        )
    }

    public var exitEvent: EventInfo {
        return EventInfo(
            name: "Beacon Exited",
            namespace: "rover",
            attributes: ["beacon": self.attributes]
        )
    }
}

// MARK: Store Requests

extension Beacon {
    struct Snapshot: Hashable {
        let objectID: NSManagedObjectID
        let uuid: UUID
        let regionIdentifier: String
    }

    public static func fetchAll(in context: NSManagedObjectContext) -> Set<Beacon> {
        let fetchRequest: NSFetchRequest<Beacon> = Beacon.beaconFetchRequest()
        let beacons: [Beacon]

        do {
            beacons = try context.fetch(fetchRequest)
        } catch {
            os_log("Failed to fetch beacons: %@", log: .persistence, type: .error, error.logDescription)
            return []
        }

        return Set(beacons)
    }

    public static func fetchAll(
        matchingRegionIdentifiers regionIdentifiers: Set<String>, in context: NSManagedObjectContext
    ) -> Set<Beacon> {
        let fetchRequest: NSFetchRequest<Beacon> = Beacon.beaconFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "regionIdentifier IN %@", regionIdentifiers)

        do {
            let beacons = try context.fetch(fetchRequest)
            return Set(beacons)
        } catch {
            os_log("Failed to fetch beacons: %@", log: .persistence, type: .error, error.logDescription)
            return []
        }
    }

    static func wildcardRegions(in context: NSManagedObjectContext, maxLength: Int) -> Set<CLBeaconRegion> {
        var snapshots = Set<Snapshot>()
        context.performAndWait {
            snapshots = fetchSnapshots(in: context)
        }

        let uuids = Set(snapshots.map(\.uuid))
        let regions = uuids.shuffled().prefix(maxLength).map { $0.region }
        return Set(regions)
    }

    static func fetchSnapshots(
        matchingRegionIdentifiers regionIdentifiers: Set<String>,
        in context: NSManagedObjectContext
    ) -> Set<Snapshot> {
        var snapshots = Set<Snapshot>()
        context.performAndWait {
            snapshots = fetchSnapshotsOnContextQueue(
                matchingRegionIdentifiers: regionIdentifiers,
                in: context
            )
        }
        return snapshots
    }

    static func fetchSnapshotsOnContextQueue(
        matchingRegionIdentifiers regionIdentifiers: Set<String>,
        in context: NSManagedObjectContext
    ) -> Set<Snapshot> {
        fetchSnapshotsOnCurrentQueue(matchingRegionIdentifiers: regionIdentifiers, in: context)
    }

    static func resolve(_ snapshots: Set<Snapshot>, in context: NSManagedObjectContext) -> Set<Beacon> {
        var beacons = Set<Beacon>()
        context.performAndWait {
            beacons = resolveOnCurrentQueue(snapshots, in: context)
        }
        return beacons
    }

    static func resolveOnContextQueue(_ snapshots: Set<Snapshot>, in context: NSManagedObjectContext)
        -> Set<Beacon>
    {
        resolveOnCurrentQueue(snapshots, in: context)
    }

    private static func fetchSnapshots(in context: NSManagedObjectContext) -> Set<Snapshot> {
        let fetchRequest: NSFetchRequest<Beacon> = Beacon.beaconFetchRequest()

        do {
            let beacons = try context.fetch(fetchRequest)
            return Set(
                beacons.map {
                    Snapshot(
                        objectID: $0.objectID,
                        uuid: $0.uuid,
                        regionIdentifier: $0.regionIdentifier
                    )
                }
            )
        } catch {
            os_log("Failed to fetch beacons: %@", log: .persistence, type: .error, error.logDescription)
            return []
        }
    }

    private static func fetchSnapshotsOnCurrentQueue(
        matchingRegionIdentifiers regionIdentifiers: Set<String>,
        in context: NSManagedObjectContext
    ) -> Set<Snapshot> {
        let fetchRequest: NSFetchRequest<Beacon> = Beacon.beaconFetchRequest()
        fetchRequest.predicate = NSPredicate(format: "regionIdentifier IN %@", regionIdentifiers)

        do {
            let beacons = try context.fetch(fetchRequest)
            return Set(
                beacons.map {
                    Snapshot(
                        objectID: $0.objectID,
                        uuid: $0.uuid,
                        regionIdentifier: $0.regionIdentifier
                    )
                }
            )
        } catch {
            os_log("Failed to fetch beacons: %@", log: .persistence, type: .error, error.logDescription)
            return []
        }
    }

    private static func resolveOnCurrentQueue(
        _ snapshots: Set<Snapshot>,
        in context: NSManagedObjectContext
    ) -> Set<Beacon> {
        var beacons = Set<Beacon>()
        snapshots.forEach { snapshot in
            do {
                if let beacon = try context.existingObject(with: snapshot.objectID) as? Beacon {
                    beacons.insert(beacon)
                }
            } catch {
                os_log("Failed to resolve beacon: %@", log: .persistence, type: .error, error.logDescription)
            }
        }
        return beacons
    }

    public static func deleteAll(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            Beacon.beaconFetchRequest() as! NSFetchRequest<NSFetchRequestResult>
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            os_log("Failed to delete beacons: %@", log: .persistence, type: .error, error.logDescription)
        }
    }
}

// MARK: Collection

extension Collection where Element == Beacon {
    public func wildCardRegions(maxLength: Int) -> Set<CLBeaconRegion> {
        let uuids = self.map { $0.uuid }
        let unique = Set(uuids)

        let regions = unique.shuffled().prefix(maxLength).map { $0.region }

        return Set<CLBeaconRegion>(regions)
    }
}
