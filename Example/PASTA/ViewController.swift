//
//  ViewController.swift
//  PASTA
//
//  Created by Aaron Krämer on 09/18/2017.
//  Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import UIKit
import PASTA
import Metron

class ViewController: UIViewController {

    var tangibles = Set<PASTATangible>()
    var orientationLabels = [PASTATangible: (UILabel, UILabel)]()
    let labelOffset: CGFloat = 40

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

        if let (initial, fixed) = orientationLabels[tangible] {
            initial.center = tangible.center + tangible.initialOrientationVector * (tangible.radius + labelOffset)
            if let orientationVector = tangible.orientationVector {
                fixed.center = tangible.center + orientationVector * (tangible.radius + labelOffset)
            }
        }
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

        let initialOrientationCenter = tangible.center + tangible.initialOrientationVector *
                (tangible.radius + labelOffset)
        let initialOrientationLabel = UILabel()
        initialOrientationLabel.text = "IO"
        initialOrientationLabel.frame = CGRect(center: initialOrientationCenter, edges: 20)
        tangibleView.addSubview(initialOrientationLabel)

        let orientationLabel = UILabel()
        orientationLabel.text = "O"

        if let orientationVector = tangible.orientationVector {
            let orientationCenter = tangible.center + orientationVector * (tangible.radius + labelOffset)

            orientationLabel.frame = CGRect(center: orientationCenter, edges: 20)

            tangibleView.addSubview(orientationLabel)
        }
        orientationLabels[tangible] = (initialOrientationLabel, orientationLabel)

        print("✅", tangible.patternIdentifier ?? "no identifier")
        print("✅", tangible)

        tangibles.insert(tangible)
    }

    func tangibleDidBecomeInactive(_ tangible: PASTATangible) {
        print("❌", tangible.patternIdentifier ?? "no identifier")
        print("❌", tangible)

        tangibles.remove(tangible)
        if let (initial, fixed) = orientationLabels[tangible] {
            initial.removeFromSuperview()
            fixed.removeFromSuperview()
            orientationLabels[tangible] = nil
        }
    }

    func tangible(_ tangible: PASTATangible, lost marker: PASTAMarker) {
        marker.backgroundColor = UIColor.blue
    }

    func tangible(_ tangible: PASTATangible, recovered marker: PASTAMarker) {
        marker.backgroundColor = UIColor.green
    }
}
