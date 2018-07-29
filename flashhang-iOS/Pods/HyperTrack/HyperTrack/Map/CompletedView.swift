//
//  CompletedView.swift
//  HyperTrack
//
//  Created by Vibes on 5/31/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

class CompletedView : UIView {
    
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var origin: UILabel!
    @IBOutlet weak var destination: UILabel!
    
    func completeUpdate( startTime : Date, endTime : Date, origin : String, destination : String) {
        
        self.startTime.text = DateFormatter.localizedString(from: startTime, dateStyle: .short, timeStyle: .short)
        
        self.endTime.text = DateFormatter.localizedString(from:endTime, dateStyle: .short, timeStyle: .short)
        
        self.origin.text = origin
        self.destination.text = destination
        
    }
    
}
