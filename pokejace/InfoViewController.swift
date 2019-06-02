//
//  InfoViewController.swift
//  pokejace
//
//  Created by Brandon Chong on 2/27/19.
//  Copyright © 2019 Brandon Chong. All rights reserved.
//

import UIKit
import CoreData

class InfoViewController: UIViewController
{
    var pokemons = [Pokemon]()
    var shinyExist: Bool = false
    var data = [NSManagedObject]()
    
    var appDelegate: AppDelegate?
    var managedContext: NSManagedObjectContext?
    
    weak var delegate: ViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        //self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 430)
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        
        for pokemon in pokemons {
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PokemonMO")
                fetchReq.predicate = NSPredicate(format: "name = %@", pokemon.name)
                fetchReq.fetchLimit = 1
                fetchReq.returnsObjectsAsFaults = false
            let fetchRes = try! managedContext?.fetch(fetchReq)
            guard let nmoRes = fetchRes?.first as? NSManagedObject else { return }
            self.data.append(nmoRes)
        }
        print(self.data)
        
        if pokemons.count < 2 {
            self.navigationItem.title = pokemons[0].name
            self.shinyExist = pokemons[0].shinyExists
            
            let pokemonImageID = pokemons[0].id
            let pokemonImageView = UIImageView(image: UIImage(named: String(pokemonImageID)))
                pokemonImageView.contentMode = .scaleAspectFit
                pokemonImageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pokemonImageView)
            pokemonImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            pokemonImageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            pokemonImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
            if self.shinyExist {
                let pokemonShinyImageView = UIImageView(image: UIImage(named: String(pokemonImageID) + "_shiny"))
                    pokemonShinyImageView.contentMode = .scaleAspectFit
                    pokemonShinyImageView.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(pokemonShinyImageView)
                pokemonShinyImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
                pokemonShinyImageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
                pokemonShinyImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
                pokemonShinyImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
                pokemonImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            } else {
                pokemonImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            }
            view.addSubview(caughtLabel)
            view.addSubview(caughtSwitch)
            if self.shinyExist {
                view.addSubview(shinyLabel)
                view.addSubview(shinySwitch)
            }
            view.addSubview(luckyLabel)
            view.addSubview(luckySwitch)
            view.addSubview(perfectLabel)
            view.addSubview(perfectSwitch)
            
            caughtLabel.topAnchor.constraint(equalTo: pokemonImageView.bottomAnchor, constant: 20).isActive = true
            caughtSwitch.topAnchor.constraint(equalTo: pokemonImageView.bottomAnchor, constant: 20).isActive = true
            
            caughtSwitch.isOn = pokemons[0].caught
            caughtSwitch.addTarget(self, action: #selector(self.caughtSwitchValueDidChange), for: .valueChanged)
            
            if caughtSwitch.isOn {
                shinySwitch.isOn = pokemons[0].caughtShiny
                shinySwitch.addTarget(self, action: #selector(self.shinySwitchValueDidChange), for: .valueChanged)
                
                luckySwitch.isOn = pokemons[0].haveLucky
                luckySwitch.addTarget(self, action: #selector(self.luckySwitchValueDidChange), for: .valueChanged)
                
                perfectSwitch.isOn = pokemons[0].havePerfect
                perfectSwitch.addTarget(self, action: #selector(self.perfectSwitchValueDidChange), for: .valueChanged)
            } else {
                shinySwitch.isEnabled = false
                luckySwitch.isEnabled = false
                perfectSwitch.isEnabled = false
            }
        } else {
            self.navigationItem.title = "Multiple Pokemon"
            
            view.addSubview(caughtLabel)
            view.addSubview(caughtSwitch)
            view.addSubview(shinyLabel)
            view.addSubview(shinySwitch)
            view.addSubview(luckyLabel)
            view.addSubview(luckySwitch)
            view.addSubview(perfectLabel)
            view.addSubview(perfectSwitch)
            
            caughtLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            caughtSwitch.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
            
            caughtSwitch.addTarget(self, action: #selector(self.caughtSwitchValueDidChange), for: .valueChanged)
            shinySwitch.addTarget(self, action: #selector(self.shinySwitchValueDidChange), for: .valueChanged)
            luckySwitch.addTarget(self, action: #selector(self.luckySwitchValueDidChange), for: .valueChanged)
            perfectSwitch.addTarget(self, action: #selector(self.perfectSwitchValueDidChange), for: .valueChanged)
            shinySwitch.isEnabled = false
            luckySwitch.isEnabled = false
            perfectSwitch.isEnabled = false
        }
        
        self.setupAutoLayout()
    }
    
    //Using NSBatchUpdateRequest
    func batchUpdate(key: String, value: Bool) {
        for object in self.data {
            object.setValue(value, forKey: key)
        }
        NotificationCenter.default.post(name: NSNotification.Name("refresh"), object: nil)
    }
    
    @objc func caughtSwitchValueDidChange(sender: UISwitch!) {
        sender.isOn = !sender.isOn
        self.batchUpdate(key: "caught", value: sender.isOn)
        self.saveCoreData()
        if (sender.isOn) {
            shinySwitch.isEnabled = true
            luckySwitch.isEnabled = true
            perfectSwitch.isEnabled = true
            shinySwitch.addTarget(self, action: #selector(self.shinySwitchValueDidChange), for: .valueChanged)
            luckySwitch.addTarget(self, action: #selector(self.luckySwitchValueDidChange), for: .valueChanged)
            perfectSwitch.addTarget(self, action: #selector(self.perfectSwitchValueDidChange), for: .valueChanged)
        } else {
            shinySwitch.isEnabled = false
            luckySwitch.isEnabled = false
            perfectSwitch.isEnabled = false
            shinySwitch.isOn = false
            luckySwitch.isOn = false
            perfectSwitch.isOn = false
            self.batchUpdate(key: "caughtShiny", value: false)
            self.batchUpdate(key: "haveLucky", value: false)
            self.batchUpdate(key: "havePerfect", value: false)
            self.saveCoreData()
        }
    }
    @objc func shinySwitchValueDidChange(sender: UISwitch!) {
        sender.isOn = !sender.isOn
        
        self.batchUpdate(key: "caughtShiny", value: sender.isOn)
        self.saveCoreData()
    }
    @objc func luckySwitchValueDidChange(sender: UISwitch!) {
        sender.isOn = !sender.isOn
        self.batchUpdate(key: "haveLucky", value: sender.isOn)
        self.saveCoreData()
    }
    @objc func perfectSwitchValueDidChange(sender: UISwitch!) {
        sender.isOn = !sender.isOn
        self.batchUpdate(key: "havePerfect", value: sender.isOn)
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
        caughtLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        caughtLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        
        caughtSwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
        caughtSwitch.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 20).isActive = true
        caughtSwitch.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        
        if self.pokemons.count > 1 || self.shinyExist {
            shinyLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
            shinyLabel.topAnchor.constraint(equalTo: caughtLabel.bottomAnchor, constant: 20).isActive = true
            shinyLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            shinyLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
            shinySwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
            shinySwitch.topAnchor.constraint(equalTo: caughtSwitch.bottomAnchor, constant: 20).isActive = true
            shinySwitch.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 20).isActive = true
            shinySwitch.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
            
            luckyLabel.topAnchor.constraint(equalTo: shinyLabel.bottomAnchor, constant: 20).isActive = true
            luckySwitch.topAnchor.constraint(equalTo: shinySwitch.bottomAnchor, constant: 20).isActive = true
        } else {
            luckyLabel.topAnchor.constraint(equalTo: caughtLabel.bottomAnchor, constant: 20).isActive = true
            luckySwitch.topAnchor.constraint(equalTo: caughtSwitch.bottomAnchor, constant: 20).isActive = true
        }
        
        luckyLabel.heightAnchor.constraint(equalToConstant: 31).isActive = true
        luckyLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        luckyLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor, constant: 0).isActive = true
        luckySwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
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
    
    // UI Stuff
    private let caughtLabel: UILabel = {
        let label = UILabel()
        label.text = "Caught"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let caughtSwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        return uiSwitch
    }()
    private let shinyLabel: UILabel = {
        let label = UILabel()
        label.text = "Caught Shiny"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let shinySwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        return uiSwitch
    }()
    private let luckyLabel: UILabel = {
        let label = UILabel()
        label.text = "Have Lucky"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let luckySwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        return uiSwitch
    }()
    private let perfectLabel: UILabel = {
        let label = UILabel()
        label.text = "Have Perfect IV"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()
    private let perfectSwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        return uiSwitch
    }()
}
