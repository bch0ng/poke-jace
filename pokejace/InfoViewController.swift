//
//  InfoViewController.swift
//  pokejace
//
//  Created by Brandon Chong on 2/27/19.
//  Copyright © 2019 Brandon Chong. All rights reserved.
//

import UIKit
import CoreData

class InfoViewController: UIViewController {
    var filteredIndex: Int = -1
    var pokemonName: String = "Jace"
    var pokemonNames = [String]()
    var dataIndex: Int = -1
    
    var appDelegate: AppDelegate?
    var managedContext: NSManagedObjectContext?
    var data: NSManagedObject?
    
    weak var delegate: ViewController!
    
    private let caughtLabel: UILabel = {
        let label = UILabel()
        label.text = "Caught"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let caughtSwitch: UISwitch = {
        let caught = UISwitch()
        caught.translatesAutoresizingMaskIntoConstraints = false
        return caught
    }()
    private let shinyLabel: UILabel = {
        let label = UILabel()
        label.text = "Caught Shiny"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let shinySwitch: UISwitch = {
        let caught = UISwitch()
        caught.translatesAutoresizingMaskIntoConstraints = false
        return caught
    }()
    private let luckyLabel: UILabel = {
        let label = UILabel()
        label.text = "Have Lucky"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let luckySwitch: UISwitch = {
        let caught = UISwitch()
        caught.translatesAutoresizingMaskIntoConstraints = false
        return caught
    }()
    private let perfectLabel: UILabel = {
        let label = UILabel()
        label.text = "Have Perfect IV"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let perfectSwitch: UISwitch = {
        let caught = UISwitch()
        caught.translatesAutoresizingMaskIntoConstraints = false
        return caught
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PokemonMO")
            fetchReq.predicate = NSPredicate(format: "name = %@", pokemonName)
            fetchReq.fetchLimit = 1
            fetchReq.returnsObjectsAsFaults = false
        let fetchRes = try! managedContext?.fetch(fetchReq)
        data = fetchRes?.first as? NSManagedObject
        
        dataIndex = pokemonNames.firstIndex(of: pokemonName)!
        view.backgroundColor = .white
        self.navigationItem.title = self.delegate.data[dataIndex].name

        view.addSubview(caughtLabel)
        view.addSubview(caughtSwitch)
        view.addSubview(shinyLabel)
        view.addSubview(shinySwitch)
        view.addSubview(luckyLabel)
        view.addSubview(luckySwitch)
        view.addSubview(perfectLabel)
        view.addSubview(perfectSwitch)
        
        caughtSwitch.isOn = self.delegate.data[dataIndex].caught
        caughtSwitch.addTarget(self, action: #selector(self.caughtSwitchValueDidChange), for: .valueChanged)
        
        if (caughtSwitch.isOn) {
            shinySwitch.isOn = self.delegate.data[dataIndex].caughtShiny
            shinySwitch.addTarget(self, action: #selector(self.shinySwitchValueDidChange), for: .valueChanged)
        
            luckySwitch.isOn = self.delegate.data[dataIndex].haveLucky
            luckySwitch.addTarget(self, action: #selector(self.luckySwitchValueDidChange), for: .valueChanged)
        
            perfectSwitch.isOn = self.delegate.data[dataIndex].havePerfect
            perfectSwitch.addTarget(self, action: #selector(self.perfectSwitchValueDidChange), for: .valueChanged)
        } else {
            shinySwitch.isEnabled = false
            luckySwitch.isEnabled = false
            perfectSwitch.isEnabled = false
        }
        self.setupAutoLayout()
    }
    
    @objc func caughtSwitchValueDidChange(sender:UISwitch!) {
        sender.isOn = !sender.isOn
        self.data?.setValue(sender.isOn, forKey: "caught")
        self.delegate.data[dataIndex].caught = sender.isOn
        self.delegate.filteredData[filteredIndex].caught = sender.isOn
        self.saveCoreData()
        if (sender.isOn) {
            shinySwitch.isEnabled = true
            luckySwitch.isEnabled = true
            perfectSwitch.isEnabled = true
            
            shinySwitch.isOn = self.delegate.data[dataIndex].caughtShiny
            shinySwitch.addTarget(self, action: #selector(self.shinySwitchValueDidChange), for: .valueChanged)
            
            luckySwitch.isOn = self.delegate.data[dataIndex].haveLucky
            luckySwitch.addTarget(self, action: #selector(self.luckySwitchValueDidChange), for: .valueChanged)
            
            perfectSwitch.isOn = self.delegate.data[dataIndex].havePerfect
            perfectSwitch.addTarget(self, action: #selector(self.perfectSwitchValueDidChange), for: .valueChanged)
        } else {
            shinySwitch.isEnabled = false
            luckySwitch.isEnabled = false
            perfectSwitch.isEnabled = false
            shinySwitch.isOn = false
            luckySwitch.isOn = false
            perfectSwitch.isOn = false
            self.data?.setValue(false, forKey: "caughtShiny")
            self.delegate.data[dataIndex].caughtShiny = false
            self.delegate.filteredData[filteredIndex].caughtShiny = false
            self.data?.setValue(false, forKey: "haveLucky")
            self.delegate.data[dataIndex].haveLucky = false
            self.delegate.filteredData[filteredIndex].haveLucky = false
            self.data?.setValue(false, forKey: "havePerfect")
            self.delegate.data[dataIndex].havePerfect = false
            self.delegate.filteredData[filteredIndex].havePerfect = false
            self.saveCoreData()
        }
    }
    @objc func shinySwitchValueDidChange(sender:UISwitch!) {
        sender.isOn = !sender.isOn
        self.data?.setValue(sender.isOn, forKey: "caughtShiny")
        self.delegate.data[dataIndex].caughtShiny = sender.isOn
        self.delegate.filteredData[filteredIndex].caughtShiny = sender.isOn
        self.saveCoreData()
    }
    @objc func luckySwitchValueDidChange(sender:UISwitch!) {
        sender.isOn = !sender.isOn
        self.data?.setValue(sender.isOn, forKey: "haveLucky")
        self.delegate.data[dataIndex].haveLucky = sender.isOn
        self.delegate.filteredData[filteredIndex].haveLucky = sender.isOn
        self.saveCoreData()
    }
    @objc func perfectSwitchValueDidChange(sender:UISwitch!) {
        sender.isOn = !sender.isOn
        self.data?.setValue(sender.isOn, forKey: "havePerfect")
        self.delegate.data[dataIndex].havePerfect = sender.isOn
        self.delegate.filteredData[filteredIndex].havePerfect = sender.isOn
        self.saveCoreData()
    }
    
    func saveCoreData() {
        do {
            try managedContext?.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func setupAutoLayout() {
        caughtLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
        caughtLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        caughtLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        caughtLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        caughtSwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
        caughtSwitch.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        caughtSwitch.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 20).isActive = true
        caughtSwitch.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        
        shinyLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
        shinyLabel.topAnchor.constraint(equalTo: caughtLabel.bottomAnchor, constant: 20).isActive = true
        shinyLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        shinyLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        shinySwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
        shinySwitch.topAnchor.constraint(equalTo: caughtSwitch.bottomAnchor, constant: 20).isActive = true
        shinySwitch.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 20).isActive = true
        shinySwitch.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        
        luckyLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
        luckyLabel.topAnchor.constraint(equalTo: shinyLabel.bottomAnchor, constant: 20).isActive = true
        luckyLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        luckyLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        luckySwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
        luckySwitch.topAnchor.constraint(equalTo: shinySwitch.bottomAnchor, constant: 20).isActive = true
        luckySwitch.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 20).isActive = true
        luckySwitch.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        
        perfectLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
        perfectLabel.topAnchor.constraint(equalTo: luckyLabel.bottomAnchor, constant: 20).isActive = true
        perfectLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        perfectLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        perfectSwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
        perfectSwitch.topAnchor.constraint(equalTo: luckySwitch.bottomAnchor, constant: 20).isActive = true
        perfectSwitch.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 20).isActive = true
        perfectSwitch.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
 
    }
}
