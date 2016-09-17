//
//  Controller.swift
//  Focus
//
//  Created by Eduardo Cristerna on 14/07/16.
//  Copyright © 2016 Eduardo Cristerna. All rights reserved.
//

import Alamofire

enum Actions: String {
    case LOG_IN = "PANELISTA_LOG_IN"
    case GET_DATA = "GET_MOBILE_DATA"
    case START_SURVEY = "START_ENCUESTA"
    case SAVE_ANSWERS = "SAVE_RESPUESTAS"
    case REGISTER_DEVICE = "REGISTER_DEVICE"
    case UNREGISTER_DEVICE = "UNREGISTER_DEVICE"
    case PRIVACY_POLICY = "PRIVACY_POLICY"
    case REGISTER_USER = "ALTA_PANELISTA"
}

class Controller {
    
    typealias RequestDidEndHandler = (NSDictionary) -> ()
    
    static private let alamofireManager: Alamofire.Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForResource = 60
        
        return Alamofire.Manager(configuration: configuration)
    }()
    
//    private static let baseURL = "http://ec2-52-26-0-111.us-west-2.compute.amazonaws.com/"
    private static let baseURL = "http://192.168.1.68:8888/"
    private static let apiURL = Controller.baseURL + "focus/api/controller.php"
    
    static let videosURL = Controller.baseURL + "focus/resources/videos/"
    static let imagesURL = Controller.baseURL + "focus/resources/images/"
    
    static func requestForAction(action: Actions, withParameters parameters: [String : AnyObject], withSuccessHandler successHandler: RequestDidEndHandler?, andErrorHandler errorHandler: RequestDidEndHandler? = nil) {
        var requestParameters = parameters
        requestParameters["action"] = action.rawValue
        
        self.alamofireManager.request(.POST, apiURL, parameters: requestParameters).validate().responseJSON { response in
            switch response.result {
            case .Success(let JSON):
                if let successHandler = successHandler {
                    successHandler(JSON as! NSDictionary)
                }
            case .Failure(let error):
                if let errorHandler = errorHandler {
                    errorHandler(["error" : error])
                }
            }
        }
    }
    
}
