//
//  PCViewController.swift
//  SHA1Helper_Example
//
//  Created by linjj on 2018/1/26.
//  Copyright © 2018年 JJSon. All rights reserved.
//

import UIKit
import SHA1Helper
class PCViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let filePath = NSHomeDirectory() + "/Documents/microsoft_office_2016_installer.pkg"
        SHA1Help().aaa()
//        SHA1Helper.sha1()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
