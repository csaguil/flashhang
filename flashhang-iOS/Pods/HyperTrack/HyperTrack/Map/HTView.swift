//
//  HTView.swift
//  HyperTrack
//
//  Created by Vibes on 5/24/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

class HTView: UIView {
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var reFocusButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var destinationView: UIView!
    @IBOutlet weak var statusCard: UIView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var eta: UILabel!
    @IBOutlet weak var distanceLeft: UILabel!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var cardConstraint: NSLayoutConstraint!
    @IBOutlet weak var tripIcon: UIImageView!
    
    @IBOutlet weak var touchView: UIView!
    var progressCircle = CAShapeLayer()
    var currentProgress : Double = 0
    var isCardExpanded = false
    var expandedCard : ExpandedCard? = nil
    var downloadedPhotoUrl : URL? = nil
    var statusCardEnabled = true
    var interactionViewDelegate: HTViewInteractionInternalDelegate?
    
func initMapView(mapSubView: MKMapView, interactionViewDelegate: HTViewInteractionInternalDelegate) {
        self.mapView.addSubview(mapSubView)
        self.interactionViewDelegate = interactionViewDelegate
        
        self.clearView()
    }
    
    override func awakeFromNib() {
        destinationView.shadow()
        statusCard.shadow()
        addProgressCircle()
        addExpandedCard()
    }
    
    func addProgressCircle() {
        
        let circlePath = UIBezierPath(ovalIn: progressView.bounds.insetBy(dx: 5 / 2.0, dy: 5 / 2.0))
        
        progressCircle = CAShapeLayer ()
        progressCircle.path = circlePath.cgPath
        progressCircle.strokeColor = htblack.cgColor
        progressCircle.fillColor = grey.cgColor
        progressCircle.lineWidth = 2.5
        
        progressView.layer.insertSublayer(progressCircle, at: 0)
        
        animateProgress(to: 0)
    }
    
    func addExpandedCard() {
        let bundle = Settings.getBundle()
        let expandedCard: ExpandedCard = bundle!.loadNibNamed("ExpandedCard", owner: self, options: nil)?.first as! ExpandedCard
        self.expandedCard = expandedCard
        self.statusCard.addSubview(expandedCard)
        self.statusCard.sendSubview(toBack: expandedCard)
        expandedCard.frame = CGRect(x: 0, y: 90, width: self.statusCard.frame.width, height: 155)
        self.statusCard.clipsToBounds = true
    }
    
    @IBAction func phone(_ sender: Any) {
        self.interactionViewDelegate?.didTapPhoneButton?(sender)
    }
    
    @IBAction func back(_ sender: Any) {
        self.interactionViewDelegate?.didTapBackButton?(sender)
    }
    
    @IBAction func reFocus(_ sender: Any) {
        self.interactionViewDelegate?.didTapReFocusButton?(sender, isInfoViewCardExpanded: isCardExpanded)
    }
    
    @IBAction func expandCard(_ sender: Any) {
        
        if !isCardExpanded {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.cardConstraint.constant = 160
                self.arrow.transform = CGAffineTransform(rotationAngle: 1.57)
                self.layoutIfNeeded()
            })
            
            isCardExpanded = true
        } else {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.cardConstraint.constant = 20
                self.arrow.transform = CGAffineTransform(rotationAngle: 0)
                self.layoutIfNeeded()
            })
            
            isCardExpanded = false
        }
    }
    
    func getImage(photoUrl: URL) -> UIImage? {
        do {
            print ("Downloading image...")
            let imageData = try Data.init(contentsOf: photoUrl, options: Data.ReadingOptions.dataReadingMapped)
            self.downloadedPhotoUrl = photoUrl
            return UIImage(data:imageData)
        } catch let error {
            print("Error in fetching photo: ", error.localizedDescription)
            return nil
        }
    }
    
    func customize( reFocusButon : Bool, backButton : Bool, statusCard : Bool, destinationCard : Bool) {
        
        self.reFocusButton.isHidden = !reFocusButon
        self.backButton.isHidden = !backButton
        self.destinationView.isHidden = !destinationCard
        
        if !statusCard {
            self.statusCard.frame.origin.y += self.statusCard.frame.height + 15
            self.statusCard.alpha = 0
            self.statusCardEnabled = false
            self.layoutIfNeeded()
        }
    }
    
    func animateProgress(to : Double) {
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentProgress
        animation.toValue = to
        animation.duration = 0.5
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        progressCircle.add(animation, forKey: "ani")
        self.currentProgress = to
    }
    
    func noPhone() {
        self.phoneButton.isHidden = true
        self.tripIcon.alpha = 1
    }
    
    func updateAddressView(isAddressViewShown: Bool, destinationAddress: String?) {
        if isAddressViewShown {
            self.destination.text = destinationAddress
            self.destinationView.isHidden = false
        } else {
            self.destinationView.isHidden = true
        }
    }
    
    func updateInfoView(isInfoViewShown: Bool, eta: Double, distanceLeft: Double,
                        status: String, isCompleted: Bool, userName: String,
                        lastUpdated: Date, timeElapsed: Double, distanceCovered: Double,
                        speed: Int, battery: Int, photoUrl: URL?) {
        //  Check if InfoView is disabled
        if !isInfoViewShown {
            self.statusCard.isHidden = true
            return
        }
        
        // Make InfoView visible
        self.statusCard.isHidden = false
        
        let progress = distanceCovered / (distanceCovered + distanceLeft)
        
        if isCompleted {
            self.eta.text = "\(Int(timeElapsed)) min"
            self.distanceLeft.text = "\(distanceCovered) mi"
        } else {
            self.eta.text = "ETA \(Int(eta)) min"
            self.distanceLeft.text = "\(distanceLeft) mi"
        }
        
        self.status.text = status
        animateProgress(to: progress)
        
        UIView.animate(withDuration: 0.15) {
            self.layoutIfNeeded()
        }
        
        if let expandedCard = self.expandedCard {
            
            let timeInSeconds = Int(timeElapsed * 60.0)
            let hours = timeInSeconds / 3600
            let minutes = (timeInSeconds / 60) % 60
            let seconds = timeInSeconds % 60
            
            expandedCard.timeElapsed.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
            expandedCard.distanceTravelled.text = "\(distanceCovered) mi"
            expandedCard.speed.text = "\(speed) mph"
            expandedCard.battery.text = "\(Int(battery))%"
            let lastUpdatedMins = Int(-1 * Double(lastUpdated.timeIntervalSinceNow) / 60.0)
            expandedCard.lastUpdated.text = "Last updated: \(lastUpdatedMins) mins ago"
            expandedCard.name.text = userName
            
            if let photo = photoUrl {
                if (self.downloadedPhotoUrl == nil) || (self.downloadedPhotoUrl != photo) {
                    expandedCard.photo.image = getImage(photoUrl: photo)
                }
            }
        }
    }
    
    func updateReFocusButton(isRefocusButtonShown: Bool) {
        self.reFocusButton.isHidden = !isRefocusButtonShown
    }
    
    func updateBackButton(isBackButtonShown: Bool) {
        self.backButton.isHidden = !isBackButtonShown
    }
    
    func clearView() {
        self.destinationView.isHidden = true
        self.statusCard.isHidden = true
        self.reFocusButton.isHidden = true
    }
    
    func completeActionView(startTime: Date, endTime: Date, origin: String, destination: String) {
        guard statusCardEnabled else { return }
        
        let bundle = Settings.getBundle()
        let completedView: CompletedView = bundle!.loadNibNamed("CompletedView", owner: self, options: nil)?.first as! CompletedView
        completedView.alpha = 0
        self.statusCard.addSubview(completedView)
        self.statusCard.bringSubview(toFront: completedView)
        self.statusCard.bringSubview(toFront: phoneButton)
        completedView.frame = CGRect(x: 0, y: 90, width: self.statusCard.frame.width, height: 155)
        self.statusCard.clipsToBounds = true
        self.touchView.isHidden = true
        
        self.isCardExpanded = true
        
        completedView.completeUpdate(startTime: startTime, endTime: endTime, origin: origin, destination: destination)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.cardConstraint.constant = 160
            completedView.alpha = 1
            self.arrow.alpha = 0
            self.layoutIfNeeded()
        })
    }
}
