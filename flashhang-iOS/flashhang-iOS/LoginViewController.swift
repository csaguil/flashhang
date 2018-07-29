import UIKit
import FacebookLogin

import FacebookCore
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: FlashHangViewController, LoginButtonDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(AccessToken.current != nil)
        if AccessToken.current != nil {
            self.performSegue(withIdentifier: "loginToStartHangSegue", sender: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        loginButton.delegate = self
        view.backgroundColor = UIColor.white
        
        view.addSubview(loginButton)
    }
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                // ...
                return
            }
            // User is signed in
            self.performSegue(withIdentifier: "loginToAddInterestsSegue", sender: nil)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        return
    }
    
    @IBAction func switchToSignup(_ sender: Any) {
        performSegue(withIdentifier: "loginToSignupSegue", sender: nil)
    }
}

