//
//  LoadingViewController.swift
//  Focus
//
//  Created by Eduardo Cristerna on 07/08/16.
//  Copyright © 2016 Eduardo Cristerna. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

    @IBOutlet var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let parameters: [String : AnyObject] = [
            "panelista" : "\(User.currentUser!.id)"
        ]
        
        self.spinner.hidden = false
        self.spinner.startAnimating()
        
        Controller.requestForAction(.GET_DATA, withParameters: parameters, withSuccessHandler: self.successHandler, andErrorHandler: self.errorHandler)
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Fetch
    // -----------------------------------------------------------------------------------------------------------
    
    func successHandler(response: NSDictionary) {
        var paneles: [Panel] = []
        
        if let panels = response["paneles"] as? [AnyObject] {
            for object in panels {
                let panel = object as! NSDictionary
                let newPanel = Panel(id: panel["id"] as! Int, nombre: panel["nombre"] as! String, fechaInicio: panel["fechaInicio"] as! String, fechaFin: panel["fechaFin"] as! String)
                
                var encuestas: [Encuesta] = []
                
                for object2 in panel["encuestas"] as! [AnyObject] {
                    let survey = object2 as! NSDictionary
                    let newSurvey = Encuesta(id: survey["id"] as! Int, nombre: survey["nombre"] as! String, fechaInicio: survey["fechaInicio"] as! String, fechaFin: survey["fechaFin"] as! String, contestada: survey["contestada"] as! Bool)
                    
                    var preguntas: [Pregunta] = []
                    
                    for object3 in survey["preguntas"] as! [AnyObject] {
                        let question = object3 as! NSDictionary
                        let newQuestion = Pregunta(id: question["id"] as! Int, tipo: question["tipo"] as! Int, numPregunta: question["numPregunta"] as! Int, pregunta: question["pregunta"] as! String, video: question["video"] as! String, imagen: question["imagen"] as! String, opciones: question["opciones"] as! [String])
                        
                        preguntas.append(newQuestion)
                    }
                    
                    newSurvey.preguntas = preguntas
                    encuestas.append(newSurvey)
                }
                
                newPanel.encuestas = encuestas
                paneles.append(newPanel)
            }
            
            self.appDelegate.paneles = paneles
            
            self.spinner.stopAnimating()
            self.spinner.hidden = true
            
            self.performSegueWithIdentifier("showContent", sender: nil)
        }
    }
    
    func errorHandler(response: NSDictionary) {
        self.spinner.stopAnimating()
        self.spinner.hidden = true
        
        print(response["error"])
    }

}
