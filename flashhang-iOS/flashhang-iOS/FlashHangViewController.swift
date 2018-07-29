import UIKit

class FlashHangViewController: UIViewController {
    
    let backendUrl = "https://cf2c0aad.ngrok.io/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationController?.navigationBar.barTintColor = UIColor.purple
         navigationController?.navigationBar.barStyle = .black
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

