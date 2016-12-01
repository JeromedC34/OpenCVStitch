//
//  MyOpenCV.swift
//  CVOpenStitch
//
//  Created by imac on 01/12/2016.
//  Copyright © 2016 foundry. All rights reserved.
//

import Foundation
import UIKit

class MyOpenCV {
    func main() -> UIImage {
        let img1:UIImage = UIImage()
        let img2:UIImage = UIImage()
//        CVWrapper.processImageWithOpenCV(img1)
//        CVWrapper.processImage(withOpenCV: img1)
        let img3:UIImage = CVWrapper.check2Images(img1, image2: img2)
        return img3
    }
}
