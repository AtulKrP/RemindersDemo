//
//  ViewController.swift
//  ReminderDemo
//
//  Created by Appinventiv on 19/04/17.
//  Copyright © 2017 AppinventivAppinventiv. All rights reserved.
//

import UIKit
import EventKit

class ViewController: UIViewController {
    //MARK:- Properties
    //======================================================
    var remArr:[EKReminder] = []
    let calendarDB = EKEventStore()
    var date: Date?
    var calendar:EKCalendar?
    
    //MARK:- IBOutlets
    //======================================================
    @IBOutlet weak var reminderTable: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var containerview: UIView!

    //MARK:- View LifeCycle
    //======================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpSubView()
        self.getEventCalendars()
        
    }
    //MARK:- Functions
    //======================================================
    func setUpSubView(){
        reminderTable.delegate = self
        reminderTable.dataSource = self
        datePicker.isHidden = true
        containerview.isHidden = true
        datePicker.addTarget(self, action: #selector(self.datPickerTarget(_:)), for: .valueChanged)
        getStatus()
    }
    
    func datPickerTarget(_ datePicker: UIDatePicker){
        self.date = datePicker.date
    }

    //MARK:- IBActions
    //======================================================
    @IBAction func deleteReminder(_ sender: UIButton) {
        self.getReminder()
    }
    

    @IBAction func addReminder(_ sender: UIButton) {
        self.datePicker.isHidden = false
        self.containerview.isHidden = false
    }
    
    @IBAction func okTapped(_ sender: UIButton) {
        createReminder {
            self.datePicker.isHidden = true
            self.containerview.isHidden = true
        }
    }
    
}
//MARK:- Event Kit functions
//======================================================
extension ViewController{
    
    func getStatus(){
        
        let authStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        switch authStatus {
        case .authorized:
            print("Authorised")
        case .denied:
            print("You have denied access to reminders")
        case .restricted:
            print("You have restricted access to reminders")
        case .notDetermined:
            self.calendarDB.requestAccess(to: EKEntityType.reminder) { (granted, error) in
                
                if let error = error{
                    print("Error: \(error)")
                }else if granted{
                    print("Access Granted")
                    self.getReminder()
                }else{
                    print("Please change from settings")
                }
            }
        }
    }
    
    func createReminder(completion: ()->()){
        
        let reminder = EKReminder(eventStore: self.calendarDB)
        reminder.title = "Nutrafol Reminder Testing"
        
        let alarm = EKAlarm(absoluteDate: self.date ?? Date())
        reminder.addAlarm(alarm)
        if let cal = self.calendar{
            reminder.calendar = cal
        }else{
            reminder.calendar = calendarDB.defaultCalendarForNewReminders()
        }
        
        do{
            try calendarDB.save(reminder, commit: true)
        }catch let error{
            print("Reminder failed due to error: \"\(error.localizedDescription)\"")
        }
        completion()
    }
    
    func getReminder(){
        
        
        let predicate = self.calendarDB.predicateForReminders(in: [self.calendar!])
        
        self.calendarDB.fetchReminders(matching: predicate) { (results) in
            if let results = results{
                self.remArr = results
            }
            DispatchQueue.main.async {
                self.reminderTable.reloadData()
            }
        }
    }
    
    func getEventCalendars(){
        let allCalendars = calendarDB.calendars(for: .reminder)
        let predicate = NSPredicate(format: "title matches %@", "NutrafolRemindersTested")
        let filtered = allCalendars.filter { predicate.evaluate(with: $0)}
        
        if let cal = filtered.first{
            calendar = cal
        }else{
            calendar = EKCalendar(for: .reminder, eventStore: calendarDB)
            calendar?.title = "NutrafolRemindersTested"
            calendar?.source = calendarDB.defaultCalendarForNewReminders().source
            let appDel = UIApplication.shared.delegate as! AppDelegate
            
            do {
                try calendarDB.saveCalendar(calendar!, commit: true)
            }catch let error{
                print("error: \(error)")
            }
        }
    }
    
    func editReminder(){
        
    }
}
//MARK:- UITableViewDataSource
//======================================================
extension ViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return remArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RemCellID", for: indexPath) as! RemCell
        cell.textLabel?.text = remArr[indexPath.row].title
        cell.detailTextLabel?.text = "\(remArr[indexPath.row].completionDate)"
        return cell
    }
}
//MARK:- UITableViewDelegate
//======================================================
extension ViewController: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

//MARK:- UITableViewCell
//======================================================
class RemCell: UITableViewCell{
    
}
