//
//  ViewController.swift
//  flashhang-iOS
//
//  Created by Cristian Saguil on 7/28/18.
//  Copyright © 2018 Cristian Saguil. All rights reserved.
//

import UIKit

class SignUpViewController: FlashHangViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchToLogin(_ sender: Any) {
        performSegue(withIdentifier: "signupToLoginSegue", sender: nil)
    }
    
}

