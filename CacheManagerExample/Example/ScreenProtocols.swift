//
//  HomeScreenProtocols.swift
//
//  Created by Fabio Acri on 18/04/2019.
//  Copyright © 2019 Fabio Acri. All rights reserved.
//

import UIKit
import Foundation

protocol InteractorProtocol {
    func getImage(with url: String, completionHandler: @escaping (UIImage?, Error?) -> Void)
}
