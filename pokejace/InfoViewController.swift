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
    var allPokemon = [Pokemon]()
    var data = [NSManagedObject]()
    private lazy var pokemonImageView: UIImageView = UIImageView()
    private lazy var pokemonShinyImageView: UIImageView = UIImageView()
    
    var appDelegate: AppDelegate?
    var managedContext: NSManagedObjectContext?
    
    weak var delegate: ViewController!
    
    /*
     override var shouldAutorotate: Bool {
        return false
     }
     
     override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
     }
     
     override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
     }
     */
    
    @objc func changePageOnSwipe(_ gesture: UISwipeGestureRecognizer) {
        var nextOrPrev = 0
        var nextPokemon: Pokemon = pokemons[0]
        var nextPokemonFound = false
        while !nextPokemonFound {
            if gesture.direction == .left {
                if (pokemons[0].id != 809) {
                    nextOrPrev += 1
                }
            } else {
                if (pokemons[0].id != 1) {
                    nextOrPrev -= 1
                }
            }
            let nextPokemonFilter = allPokemon.filter { $0.id == pokemons[0].id + nextOrPrev}
            if (nextPokemonFilter.count > 0) {
                nextPokemonFound = true
                nextPokemon = nextPokemonFilter[0]
            }
        }
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PokemonMO")
        fetchReq.predicate = NSPredicate(format: "id = %d", nextPokemon.id)
            fetchReq.fetchLimit = 1
            fetchReq.returnsObjectsAsFaults = false
        let fetchRes = try! managedContext?.fetch(fetchReq)
        guard let nmoRes = fetchRes?.first as? NSManagedObject else { return }
        let newPokemon = allPokemon.filter { $0.id == nextPokemon.id}[0]
        self.pokemons.removeAll()
        self.pokemons.append(newPokemon)
        self.data.removeAll()
        self.data.append(nmoRes)
        self.loadSinglePokemon()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.view.backgroundColor = .white
        //self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 430)
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        
        for pokemon in pokemons {
            let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "PokemonMO")
                fetchReq.predicate = NSPredicate(format: "id = %d", pokemon.id)
                fetchReq.fetchLimit = 1
                fetchReq.returnsObjectsAsFaults = false
            let fetchRes = try! managedContext?.fetch(fetchReq)
            guard let nmoRes = fetchRes?.first as? NSManagedObject else { return }
            self.data.append(nmoRes)
        }
        // print(self.data)

        if pokemons.count == 1 {
            let swipeToLeft = UISwipeGestureRecognizer(target: self, action: #selector(changePageOnSwipe(_:)))
                swipeToLeft.direction = .right
            self.view.addGestureRecognizer(swipeToLeft)
            let swipeToRight = UISwipeGestureRecognizer(target: self, action: #selector(changePageOnSwipe(_:)))
                swipeToRight.direction = .left
            self.view.addGestureRecognizer(swipeToRight)
            
            view.addSubview(caughtLabel)
            view.addSubview(caughtSwitch)
            view.addSubview(shinyLabel)
            view.addSubview(shinySwitch)
            view.addSubview(luckyLabel)
            view.addSubview(luckySwitch)
            view.addSubview(perfectLabel)
            view.addSubview(perfectSwitch)
            
            self.loadSinglePokemon()
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
            
            var allCaughtCount = 0
            var allShinyCount = 0
            var allLuckyCount = 0
            var allPerfectCount = 0
            
            for pokemon in pokemons {
                if pokemon.caught {
                    allCaughtCount += 1
                }
                if pokemon.caughtShiny {
                    allShinyCount += 1
                }
                if pokemon.haveLucky {
                    allLuckyCount += 1
                }
                if pokemon.havePerfect {
                    allPerfectCount += 1
                }
            }
            
            if (allCaughtCount == pokemons.count) {
                caughtSwitch.isOn = true
            }
            if (allShinyCount == pokemons.count) {
                shinySwitch.isOn = true
            }
            if (allLuckyCount == pokemons.count) {
                luckySwitch.isOn = true
            }
            if (allPerfectCount == pokemons.count) {
                perfectSwitch.isOn = true
            }
        }
        
        self.setupAutoLayout()
    }

    func loadSinglePokemon()
    {
        self.pokemonImageView.removeFromSuperview()
        self.pokemonShinyImageView.removeFromSuperview()
        self.navigationItem.title = pokemons[0].name
        self.shinyExist = pokemons[0].shinyExists
        
        let pokemonImageID = pokemons[0].id
        pokemonImageView = UIImageView(image: UIImage(named: String(pokemonImageID)))
        pokemonImageView.contentMode = .scaleAspectFit
        pokemonImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(pokemonImageView, at: 0)
        pokemonImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        pokemonImageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pokemonImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        if self.shinyExist {
            pokemonShinyImageView = UIImageView(image: UIImage(named: String(pokemonImageID) + "_shiny"))
            pokemonShinyImageView.contentMode = .scaleAspectFit
            pokemonShinyImageView.translatesAutoresizingMaskIntoConstraints = false
            self.view.insertSubview(pokemonShinyImageView, at: 1)
            pokemonShinyImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
            pokemonShinyImageView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
            pokemonShinyImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            pokemonShinyImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
            pokemonImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        } else {
            pokemonImageView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        }

        caughtLabel.topAnchor.constraint(equalTo: pokemonImageView.bottomAnchor, constant: 20).isActive = true
        caughtSwitch.topAnchor.constraint(equalTo: pokemonImageView.bottomAnchor, constant: 20).isActive = true
        
        caughtSwitch.isOn = pokemons[0].caught
        caughtSwitch.addTarget(self, action: #selector(self.caughtSwitchValueDidChange), for: .valueChanged)
        if caughtSwitch.isOn {
            shinySwitch.isEnabled = true
            luckySwitch.isEnabled = true
            perfectSwitch.isEnabled = true
            shinySwitch.isOn = pokemons[0].caughtShiny
            luckySwitch.isOn = pokemons[0].haveLucky
            perfectSwitch.isOn = pokemons[0].havePerfect
            shinySwitch.addTarget(self, action: #selector(self.shinySwitchValueDidChange), for: .valueChanged)
            luckySwitch.addTarget(self, action: #selector(self.luckySwitchValueDidChange), for: .valueChanged)
            perfectSwitch.addTarget(self, action: #selector(self.perfectSwitchValueDidChange), for: .valueChanged)
        } else {
            shinySwitch.isEnabled = false
            luckySwitch.isEnabled = false
            perfectSwitch.isEnabled = false
        }
    }
    
    //Using NSBatchUpdateRequest
    func batchUpdate(key: String, value: Bool) {
        for object in self.data {
            if (key != "caught" && object.value(forKey: "caught") as! Bool != true) {
                object.setValue(true, forKey: "caught")
            }
            if (object.value(forKey: key) as! Bool != value) {
                object.setValue(value, forKey: key)
            }
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
            if (pokemons.count == 1) {
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
