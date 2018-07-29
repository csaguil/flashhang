import UIKit

class FlashHangViewController: UIViewController {
    
    let backendUrl = "https://cf2c0aad.ngrok.io/"
    let colors = [
        "orange": UIColor(red: 255.0/255.0, green: 190.0/255.0, blue: 97.0/255.0, alpha: 100.0),
        "background": UIColor(red: 4.0/255.0, green: 19.0/255.0, blue: 38.0/255.0, alpha: 100.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationController?.navigationBar.barTintColor = colors["background"]
         navigationController?.navigationBar.barStyle = .black
        self.view.backgroundColor = colors["background"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

