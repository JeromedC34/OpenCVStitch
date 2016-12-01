//
//  ViewController.swift
//  CVOpenStitch
//
//  Created by imac on 01/12/2016.
//  Copyright © 2016 foundry. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var uiImage0: UIImageView!
    @IBOutlet weak var uiImage: UIImageView!
    @IBOutlet weak var uiImage2: UIImageView!
    override func viewDidAppear(_ animated: Bool) {
        let images:[UIImage?] = [
            UIImage(named: "pano_19_16_mid.jpg")!,
            UIImage(named: "pano_19_20_mid.jpg")!,
            UIImage(named: "pano_19_22_mid.jpg")!,
            UIImage(named: "pano_19_25_mid.jpg")!,
            nil
        ]
        uiImage.image = CVWrapper.process(with: images)
        let images2:[UIImage?] = [
            UIImage(named: "pano_19_16_mid.jpg")!,
            UIImage(named: "pano_19_22_mid.jpg")!,
            nil
        ]
        uiImage2.image = CVWrapper.process(with: images2)
        let myOpenCV:MyOpenCV = MyOpenCV()
//        uiImage0.image = myOpenCV.main()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
