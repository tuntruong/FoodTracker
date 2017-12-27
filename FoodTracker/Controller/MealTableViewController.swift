//
//  ViewController.swift
//  FoodTracker
//
//  Created by Admin on 12/27/17.
//  Copyright © 2017 Admin. All rights reserved.
//

import UIKit
import os.log
import CoreData

class MealTableViewController: UITableViewController {
    
    //MARK: Properties
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<MealEntity> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<MealEntity> = MealEntity.fetchRequest()
        
        // Configure Fetch Reqeust
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "rating", ascending: false)]
        
        // Create Fetched Result Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: AppDelegate.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Result Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    var mealsEntity: [MealEntity] = []
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        // Load the sample data.
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return mealsEntity.count
        } else {
            guard let meals = fetchedResultsController.fetchedObjects else {return 0}
            return meals.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "MealTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MealTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        if searchController.isActive {
            let meal = mealsEntity[indexPath.row]
            cell.nameLabel.text = meal.name
            cell.ratingControl.rating = Int(meal.rating)
            cell.photoImageView.image = meal.photo as? UIImage
        }
        else {
            // Configure Cell
            configureCell(cell, indexPath: indexPath)
        }
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Fetch Meal
            let meal = fetchedResultsController.object(at: indexPath)
            
            // Delete Meal
            meal.managedObjectContext?.delete(meal)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    //MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "AddItem":
            os_log("Adding a new meal.", log: OSLog.default, type: .debug)
            
        case "ShowDetail":
            guard let mealDetailViewController = segue.destination as? MealViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            // Configure Meal View Controller
            mealDetailViewController.managedObjectContext = AppDelegate.shared.persistentContainer.viewContext
            
            guard let selectedMealCell = sender as? MealTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            mealDetailViewController.meal = fetchedResultsController.object(at: indexPath)
            
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    // MARK: - Methods
    
    func configureCell(_ cell: MealTableViewCell, indexPath: IndexPath) {
        // Fetch Meal
        let meal = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        cell.nameLabel.text = meal.name
        cell.ratingControl.rating = Int(meal.rating)
        cell.photoImageView.image = meal.photo as? UIImage
    }
    
    
    //MARK: Actions
    
    @IBAction func unwindToMealList(sender: UIStoryboardSegue) {
        
    }
    
}

// MARK: - UISearchResultsUpdating

extension MealTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            return
        }
        mealsEntity = fetchedObjects.filter({ (mealEntity) -> Bool in
            let foldingNameMealEntity = mealEntity.name?.lowercased().folding(options: .diacriticInsensitive, locale: Locale.current)
            let foldingSearchText = searchText.lowercased().folding(options: .diacriticInsensitive, locale: Locale.current)
            return (foldingNameMealEntity ?? "").contains(foldingSearchText)
        })
        tableView.reloadData()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension MealTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? MealTableViewCell {
                configureCell(cell, indexPath: indexPath)
            }
            break
        default:
            break
        }
        do {
            try AppDelegate.shared.persistentContainer.viewContext.save()
        } catch {
            print("Unable to Save Changes")
            print("\(error), \(error.localizedDescription)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
