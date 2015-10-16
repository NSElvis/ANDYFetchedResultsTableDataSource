/*
import UIKit
import XCTest
import DATAStack

class PodTests: XCTestCase {
    static let cellIdentifier = "CellIdentifier"
    static let entityName = "User"
    static let modelName = "DataModel"


    func userWithName(name: String, context: NSManagedObjectContext) -> User {
        let entity = NSEntityDescription.entityForName(PodTests.entityName, inManagedObjectContext: context)!
        let user = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context) as! User
        user.name = name

        return user
    }

    func testTableViewDataSource() {
        var success = false
        let bundle = NSBundle(forClass: PodTests.self)
        let dataStack = DATAStack(modelName: PodTests.entityName, bundle: bundle, storeType: .InMemoryStoreType)

        let tableView = UITableView()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: PodTests.cellIdentifier)

        let request = NSFetchRequest(entityName: PodTests.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let dataSource = DataSource(tableView: tableView, cellIdentifier: PodTests.cellIdentifier, fetchRequest: request, sectionName: nil, mainContext: dataStack.mainContext)
    }
}
*/