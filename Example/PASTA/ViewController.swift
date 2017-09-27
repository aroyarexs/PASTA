//
//  ViewController.swift
//  PASTA
//
//  Created by Aaron Krämer on 09/18/2017.
//  Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import UIKit
import PASTA

class ViewController: UIViewController {

    var tangibles = Set<PASTATangible>()

    @IBOutlet weak var tangibleView: PASTAView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tangibleView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func whitelistDetectedTangibles() {
        tangibles.forEach { _ = tangibleView.manager.whitelist(pattern: $0.pattern, identifier: UUID().uuidString) }
    }

    @IBAction func toggleAllowAllPatterns(_ sender: UISwitch) {
        tangibleView.manager.patternWhitelistDisabled = sender.isOn
    }

    @IBAction func toggleAllowSimilarPatterns(_ sender: UISwitch) {
        tangibleView.manager.similarPatternsAllowed = sender.isOn
    }
}

extension ViewController: TangibleEvent {   // MARK: - TangibleEvent

    func tangibleMoved(_ tangible: PASTATangible) {
        tangible.layer.cornerRadius = tangible.radius
    }

    func tangibleDidBecomeActive(_ tangible: PASTATangible) {
//        tangible.useMeanValues = false
        tangible.backgroundColor = UIColor.red
        if tangible.inactiveMarkers.isEmpty {
            tangible.markers.forEach { $0.backgroundColor = UIColor.green }
        }

        tangible.layer.masksToBounds = true
        tangible.layer.cornerRadius = tangible.radius
        tangible.layer.borderWidth = 2.0

        print("✅", tangible.patternIdentifier ?? "no identifier")
        print("✅", tangible)

        tangibles.insert(tangible)
    }

    func tangibleDidBecomeInactive(_ tangible: PASTATangible) {
        print("❌", tangible.patternIdentifier ?? "no identifier")
        print("❌", tangible)

        tangibles.remove(tangible)
    }

    func tangible(_ tangible: PASTATangible, lost marker: PASTAMarker) {
        marker.backgroundColor = UIColor.blue
    }

    func tangible(_ tangible: PASTATangible, recovered marker: PASTAMarker) {
        marker.backgroundColor = UIColor.green
    }
}
