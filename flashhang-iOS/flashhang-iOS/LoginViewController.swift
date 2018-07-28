import UIKit

class LoginViewController: FlashHangViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchToSignup(_ sender: Any) {
        performSegue(withIdentifier: "loginToSignupSegue", sender: nil)
    }
    
    @IBAction func loginWithFacebook(_ sender: Any) {
        performSegue(withIdentifier: "loginToAddInterestsSegue", sender: nil)
    }
    
}

