import UIKit
import CoreData

public protocol DataSourceable: class {
    func dataSource(dataSource: DataSource, didInsertObject object: NSManagedObject, atIndexPath indexPath: NSIndexPath)
    func dataSource(dataSource: DataSource, didUpdateObject object: NSManagedObject, atIndexPath indexPath: NSIndexPath)
    func dataSource(dataSource: DataSource, didDeleteObject object: NSManagedObject, atIndexPath indexPath: NSIndexPath)
    func dataSource(dataSource: DataSource, didMoveObject object: NSManagedObject, fromIndexPath oldIndexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath)

    /*!
    * ********************
    *
    * UITableView specific
    *
    * ********************
    */

    // Sections and Headers

    func sectionIndexTitlesForDataSource(dataSource: DataSource, tableView: UITableView) -> [String]?
    func dataSource(dataSource: DataSource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
    func dataSource(dataSource: DataSource, tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    func dataSource(dataSource: DataSource, tableView: UITableView, titleForFooterInSection section: Int) -> String?

    // Editing

    func dataSource(dataSource: DataSource, tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    func dataSource(dataSource: DataSource, tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)

    // Moving or Reordering

    func dataSource(dataSource: DataSource, tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
    func dataSource(dataSource: DataSource, tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)


    /*!
    * ********************
    *
    * UICollectionView specific
    *
    * ********************
    */

    func dataSource(dataSource: DataSource, collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
}

extension DataSourceable {
    func dataSource(dataSource: DataSource, didInsertObject object: NSManagedObject, atIndexPath indexPath: NSIndexPath) {}
    func dataSource(dataSource: DataSource, didUpdateObject object: NSManagedObject, atIndexPath indexPath: NSIndexPath) {}
    func dataSource(dataSource: DataSource, didDeleteObject object: NSManagedObject, atIndexPath indexPath: NSIndexPath) {}
    func dataSource(dataSource: DataSource, didMoveObject object: NSManagedObject, fromIndexPath oldIndexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {}

    /*!
    * ********************
    *
    * UITableView specific
    *
    * ********************
    */

    // Sections and Headers

    func sectionIndexTitlesForDataSource(dataSource: DataSource, tableView: UITableView) -> [String]?  { return nil }
    func dataSource(dataSource: DataSource, tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int { return 0 }
    func dataSource(dataSource: DataSource, tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return nil }
    func dataSource(dataSource: DataSource, tableView: UITableView, titleForFooterInSection section: Int) -> String? { return nil }

    // Editing

    func dataSource(dataSource: DataSource, tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool { return false }
    func dataSource(dataSource: DataSource, tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}

    // Moving or Reordering

    func dataSource(dataSource: DataSource, tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool { return false }
    func dataSource(dataSource: DataSource, tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {}


    /*!
    * ********************
    *
    * UICollectionView specific
    *
    * ********************
    */

    func dataSource(dataSource: DataSource, collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView { return UICollectionReusableView() }
}

public class DataSource: NSObject {
    private weak var tableView: UITableView?
    private weak var collectionView: UICollectionView?
    private var sectionName: String?
    private var cellIdentifier: String
    private weak var mainContext: NSManagedObjectContext?
    private var configurationBlock: (cell: UIView, item: NSManagedObject, indexPath: NSIndexPath) -> ()

    public weak var delegate: DataSourceable?

    private var fetchedResultsController: NSFetchedResultsController
    private var cachedSectionNames: [String]?

    private lazy var objectChanges: [NSFetchedResultsChangeType : [NSIndexPath]] = {
        return [NSFetchedResultsChangeType : [NSIndexPath]]()

    }()

    private lazy var sectionChanges: [NSFetchedResultsChangeType : NSMutableIndexSet] = {
        return [NSFetchedResultsChangeType : NSMutableIndexSet]()
    }()

    public convenience init(tableView: UITableView, cellIdentifier: String, fetchRequest: NSFetchRequest, mainContext: NSManagedObjectContext, sectionName: String?, configuration: (cell: UIView, item: NSManagedObject, indexPath: NSIndexPath) -> ()) {
        self.init(cellIdentifier: cellIdentifier, fetchRequest: fetchRequest, mainContext: mainContext, sectionName: sectionName, configuration: configuration)

        self.tableView = tableView
        self.tableView?.dataSource = self
    }

    public convenience init(collectionView: UICollectionView, cellIdentifier: String, fetchRequest: NSFetchRequest, mainContext: NSManagedObjectContext, sectionName: String?, configuration: (cell: UIView, item: NSManagedObject, indexPath: NSIndexPath) -> ()) {
        self.init(cellIdentifier: cellIdentifier, fetchRequest: fetchRequest, mainContext: mainContext, sectionName: sectionName, configuration: configuration)

        self.collectionView = collectionView
        self.collectionView?.dataSource = self

        self.collectionView?.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DataSourceCollectionViewHeader.Identifier);
    }

    private init(cellIdentifier: String, fetchRequest: NSFetchRequest, mainContext: NSManagedObjectContext, sectionName: String?, configuration: (cell: UIView, item: NSManagedObject, indexPath: NSIndexPath) -> ()) {
        self.cellIdentifier = cellIdentifier
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainContext, sectionNameKeyPath: sectionName, cacheName: nil)
        self.configurationBlock = configuration

        super.init()

        self.fetchedResultsController.delegate = self

        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print("Error fetching objects")
        }
    }
}

extension DataSource: UITableViewDataSource {
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRowsInSection = 0

        if let sections = self.fetchedResultsController.sections {
            numberOfRowsInSection = sections[section].numberOfObjects
        }

        return numberOfRowsInSection
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath)

        self.configureCell(cell, indexPath: indexPath)
        
        return cell
    }

    // Sections and Headers

    public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return self.delegate?.sectionIndexTitlesForDataSource(self, tableView: tableView)
    }

    public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return self.delegate?.dataSource(self, tableView: tableView, sectionForSectionIndexTitle: title, atIndex: index) ?? 0
    }

    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.delegate?.dataSource(self, tableView: tableView, titleForHeaderInSection: section)
    }

    public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self.delegate?.dataSource(self, tableView: tableView, titleForFooterInSection: section)
    }

    // Editing

    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.delegate?.dataSource(self, tableView: tableView, canEditRowAtIndexPath: indexPath) ?? false
    }

    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.dataSource(self, tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
    }

    // Moving or Reordering

    public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.delegate?.dataSource(self, tableView: tableView, canMoveRowAtIndexPath: indexPath) ?? false
    }

    public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.delegate?.dataSource(self, tableView: tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
}

extension DataSource: UICollectionViewDataSource {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfItemsInSection = 0

        if let sections = self.fetchedResultsController.sections {
            numberOfItemsInSection = sections[section].numberOfObjects
        }

        return numberOfItemsInSection
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.cellIdentifier, forIndexPath: indexPath)

        self.configureCell(cell, indexPath: indexPath)

        return cell
    }

    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return self.delegate?.dataSource(self, collectionView: collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath) ?? UICollectionReusableView()
    }
}

extension DataSource: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if let tableView = self.tableView {
            tableView.beginUpdates()
        } else if let _ = self.collectionView {
            self.sectionChanges = [NSFetchedResultsChangeType : NSMutableIndexSet]()
            self.objectChanges = [NSFetchedResultsChangeType : [NSIndexPath]]()
        }
    }

    public func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        self.cachedSectionNames = nil

        if let tableView = self.tableView {
            switch type {
            case .Insert:
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
                break
            case .Delete:
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
                break
            case .Move, .Update:
                tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
                break
            }
        } else if let _ = self.collectionView {
            switch type {
            case .Insert, .Delete:
                if let changeSet = self.sectionChanges[type] {
                    changeSet.addIndex(sectionIndex)
                } else {
                    self.sectionChanges[type] = NSMutableIndexSet(index: sectionIndex)
                }
                break
            case .Move, .Update:
                break
            }
        }
    }

    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if let tableView = self.tableView {
            switch type {
            case .Insert:
                if let newIndexPath = newIndexPath, anObject = anObject as? NSManagedObject {
                    tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
                    self.delegate?.dataSource(self, didInsertObject: anObject, atIndexPath: newIndexPath)
                }
                break
            case .Delete:
                if let indexPath = indexPath, anObject = anObject as? NSManagedObject {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    self.delegate?.dataSource(self, didDeleteObject: anObject, atIndexPath: indexPath)
                }
                break
            case .Update:
                if let indexPath = indexPath {
                    if tableView.indexPathsForVisibleRows?.indexOf(indexPath) != nil {
                        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                            self.configureCell(cell, indexPath: indexPath)
                        }

                        if let anObject = anObject as? NSManagedObject {
                            self.delegate?.dataSource(self, didUpdateObject: anObject, atIndexPath: indexPath)
                        }
                    }
                }
                break
            case .Move:
                if let indexPath = indexPath, newIndexPath = newIndexPath {
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)

                    if let oldCell = tableView.cellForRowAtIndexPath(indexPath), newCell = tableView.cellForRowAtIndexPath(newIndexPath) {
                        self.configureCell(oldCell, indexPath: indexPath)
                        self.configureCell(newCell, indexPath: newIndexPath)

                        if let anObject = anObject as? NSManagedObject {
                            self.delegate?.dataSource(self, didMoveObject: anObject, fromIndexPath: indexPath, toIndexPath: newIndexPath)
                        }
                    }
                }
                break
            }
        } else if let _ = self.collectionView {
            var changeSet = self.objectChanges[type] ?? [NSIndexPath]()

            switch type {
            case .Insert:
                if let newIndexPath = newIndexPath {
                    changeSet.append(newIndexPath)
                }
                break
            case .Delete, .Update:
                if let indexPath = indexPath {
                    changeSet.append(indexPath)
                }
            case .Move:
                if let indexPath = indexPath, newIndexPath = newIndexPath {
                    changeSet.append(indexPath)
                    changeSet.append(newIndexPath)
                }
                break
            }

            self.objectChanges[type] = changeSet
        }
    }

    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if let tableView = self.tableView {
            tableView.endUpdates()
        } else if let _ = self.collectionView {
            let moves = self.objectChanges[.Move]
            if let moves = moves {
                if moves.count > 0 {
                    var updatedMoves = [NSIndexPath]()
                    if let insertSections = self.sectionChanges[.Insert], deleteSections = self.sectionChanges[.Delete] {
                        let fromIndexPath = moves[0]
                        let toIndexPath = moves[1]

                        if deleteSections.containsIndex(fromIndexPath.section) {
                            if insertSections.containsIndex(toIndexPath.section) == false {
                                if var changeSet = self.objectChanges[.Insert] {
                                    changeSet.append(toIndexPath)
                                    self.objectChanges[.Insert] = changeSet
                                } else {
                                    self.objectChanges[.Insert] = [toIndexPath]
                                }
                            }
                        } else if insertSections.containsIndex(toIndexPath.section) {
                            if var changeSet = self.objectChanges[.Delete] {
                                changeSet.append(fromIndexPath)
                                self.objectChanges[.Delete] = changeSet
                            } else {
                                self.objectChanges[.Delete] = [fromIndexPath]
                            }
                        } else {
                            updatedMoves.appendContentsOf(moves)
                        }
                    }

                    if updatedMoves.count > 0 {
                        self.objectChanges[.Move] = updatedMoves
                    } else {
                        self.objectChanges.removeValueForKey(.Move)
                    }
                }

                if let deletes = self.objectChanges[.Delete] {
                    if deletes.count > 0 {
                        let sections = self.sectionChanges[.Delete]
                        let filtered = deletes.filter({ element -> Bool in
                            return (sections?.containsIndex(element.section))!
                        })
                        self.objectChanges[.Delete] = filtered
                    }
                }

                if let inserts = self.objectChanges[.Insert] {
                    if inserts.count > 0 {
                        let sections = self.sectionChanges[.Insert]
                        let filtered = inserts.filter({ element -> Bool in
                            return (sections?.containsIndex(element.section))!
                        })
                        self.objectChanges[.Insert] = filtered
                    }
                }

                if let collectionView = self.collectionView {
                    collectionView.performBatchUpdates({
                        if let deletedSections = self.sectionChanges[.Delete] {
                            collectionView.deleteSections(deletedSections)
                        }

                        if let insertedSections = self.sectionChanges[.Insert] {
                            collectionView.insertSections(insertedSections)
                        }

                        if let deleteItems = self.objectChanges[.Delete] {
                            collectionView.deleteItemsAtIndexPaths(deleteItems)
                        }

                        if let insertedItems = self.objectChanges[.Insert] {
                            collectionView.insertItemsAtIndexPaths(insertedItems)
                        }

                        if let reloadItems = self.objectChanges[.Update] {
                            collectionView.reloadItemsAtIndexPaths(reloadItems)
                        }

                        if let moveItems = self.objectChanges[.Move] {
                            collectionView.moveItemAtIndexPath(moveItems[0], toIndexPath: moveItems[1])
                        }

                        }, completion: nil)
                }
            }
        }
    }

    private func configureCell(cell: UIView, indexPath: NSIndexPath) {
        var item: NSManagedObject?

        let rowIsInsideBounds = indexPath.row < self.fetchedResultsController.fetchedObjects?.count
        if rowIsInsideBounds {
            item = self.fetchedResultsController.objectAtIndexPath(indexPath) as? NSManagedObject
        }

        if let item = item {
            self.configurationBlock(cell: cell, item: item, indexPath: indexPath)
        }
    }
}