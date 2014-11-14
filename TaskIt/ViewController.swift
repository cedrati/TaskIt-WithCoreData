//
//  ViewController.swift
//  TaskIt
//
//  Created by Eliot Arntz on 9/20/14.
//  Copyright (c) 2014 BitFountain. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
    let persistentStoreCoordinator = (UIApplication.sharedApplication().delegate as AppDelegate).persistentStoreCoordinator
    
    var fetchedResultsController:NSFetchedResultsController = NSFetchedResultsController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        fetchedResultsController = getFetchedResultsController()
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(nil)

        self.registerForiCloudNotifications()
        
        let ubiquitousURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("TaskItCloud")
        println("url: \(ubiquitousURL)")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showTaskDetail" {
            let detailVC: TaskDetailViewController = segue.destinationViewController as TaskDetailViewController
            let indexPath = self.tableView.indexPathForSelectedRow()
            let thisTask = fetchedResultsController.objectAtIndexPath(indexPath!) as TaskModel
            detailVC.detailTaskModel = thisTask
        }
        else if segue.identifier == "showTaskAdd" {
            let addTaskVC:AddTaskViewController = segue.destinationViewController as AddTaskViewController
        }
    }
    
    @IBAction func addButtonTapped(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("showTaskAdd", sender: self)
    }
    
    
    
    
    //UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let thisTask = fetchedResultsController.objectAtIndexPath(indexPath) as TaskModel
        
        println(thisTask)
        
        var cell: TaskCell = tableView.dequeueReusableCellWithIdentifier("myCell") as TaskCell
        
        cell.taskLabel.text = thisTask.task
        cell.descriptionLabel.text = thisTask.subtask
        cell.dateLabel.text = Date.toString(date: thisTask.date)
        
        return cell
    }
    
    //UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        println(indexPath.row)
        
        performSegueWithIdentifier("showTaskDetail", sender: self)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "To do"
        }
        else {
            return "Completed"
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let thisTask = fetchedResultsController.objectAtIndexPath(indexPath) as TaskModel
        
        if indexPath.section == 0 {
            thisTask.completed = true
        }
        else {
            thisTask.completed = false
        }
        (UIApplication.sharedApplication().delegate as AppDelegate).saveContext()
    }
    
    // NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.reloadData()
    }
    
    //Helper
    
    
    func taskFetchRequest() -> NSFetchRequest {
        let fetchRequest =  NSFetchRequest(entityName: "TaskModel")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        let completedDescriptor = NSSortDescriptor(key: "completed", ascending: true)
        fetchRequest.sortDescriptors = [completedDescriptor, sortDescriptor]
        
        return fetchRequest
    }
    
    func getFetchedResultsController() -> NSFetchedResultsController {
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: taskFetchRequest(), managedObjectContext: managedObjectContext, sectionNameKeyPath: "completed", cacheName: nil)
        
        return fetchedResultsController
    }
    
    // iCloud
    
    func registerForiCloudNotifications() {
        var notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "storesWillChange:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object:persistentStoreCoordinator)
        
        notificationCenter.addObserver(self, selector: "storesDidChange:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object:persistentStoreCoordinator)

        notificationCenter.addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChanges:", name:NSPersistentStoreDidImportUbiquitousContentChangesNotification, object:persistentStoreCoordinator)
        
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        println("persistent store import")
        managedObjectContext.performBlock { () -> Void in
            self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    func storesWillChange(notification: NSNotification) {
        println("stores will change")
        managedObjectContext.performBlockAndWait { () -> Void in
            var error: NSError?
            
            if self.managedObjectContext.hasChanges {
                let success = self.managedObjectContext.save(&error)
                
//                if success == nil && error {
//                    println("error with stores will change notification: \(error)")
//                }
                
                
            }
            
            self.managedObjectContext.reset()
            
        }
        
        tableView.reloadData()
    }
    
    func storesDidChange(notification: NSNotification) {
        println("stores did change")
        tableView.reloadData()
    }

}

