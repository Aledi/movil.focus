//
//  LogInViewController.swift
//  Focus
//
//  Created by Eduardo Cristerna on 13/07/16.
//  Copyright © 2016 Eduardo Cristerna. All rights reserved.
//

import UIKit

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var usernameText: UITextField!
    @IBOutlet var passwordText: UITextField!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Lifecycle
    // -----------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: false)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Keyboard
    // -----------------------------------------------------------------------------------------------------------
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            if (view.frame.origin.y == 0) {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            if (view.frame.origin.y != 0) {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField.tag == 10) {
            self.passwordText.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            self.logIn()
        }
        
        return false
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Actions
    // -----------------------------------------------------------------------------------------------------------
    
    @IBAction func cancelRegistration(segue: UIStoryboardSegue) {
        self.dismissSegueSourceViewController(segue)
    }
    
    @IBAction func doneRegistration(segue: UIStoryboardSegue) {
        self.dismissSegueSourceViewController(segue)
        
        self.usernameText.text = "Carlos"
        self.passwordText.text = "pass"
        
        self.logIn()
    }
    
    @IBAction func logInAttempt(sender: AnyObject) {
        self.logIn()
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - LogIn
    // -----------------------------------------------------------------------------------------------------------
    
    func logIn() {
        let parameters: [String : AnyObject] = [
            "username" : self.usernameText.text!,
            "password" : self.passwordText.text!
        ]
        
        self.spinner.startAnimating()
        
        Controller.requestForAction(.LOG_IN, withParameters: parameters, withSuccessHandler: self.successHandler, andErrorHandler: self.errorHandler)
    }
    
    func successHandler(response: NSDictionary) {
        if (response["status"] as? String == "SUCCESS") {
            if let id = response["id"] as? Int, username = response["username"] as? String, email = response["email"] as? String, nombre = response["nombre"] as? String, genero = response["genero"] as? Int {
                let user = User(id: id, username: username, email: email, nombre: nombre, genero: genero)
                User.saveUser(user)
                
                if let user = User.currentUser {
                    NSUserDefaults.saveUserDefaults(user)
                }
            }
            
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
            }
            
            self.appDelegate.registerForPushNotifications()
            self.spinner.stopAnimating()
            self.performSegueWithIdentifier("logIn", sender: self)
        } else {
            self.presentAlertWithTitle("Usuario o contraseña incorrectos", withMessage: "Verifique su usuario y contraseña", withButtonTitles: ["OK"], withButtonStyles: [.Cancel], andButtonHandlers: [nil])
        }
        
        self.spinner.stopAnimating()
    }
    
    func errorHandler(response: NSDictionary) {
        self.spinner.stopAnimating()
        var alertTitle = ""
        var alertMessage = ""
        
        switch (response["error"] as! NSError).code {
        case -1009:
            alertTitle = "Sin conexión a internet"
            alertMessage = "Para utilizar la aplicación, su dispositivo debe estar conectado a internet."
        case -1003:
            alertTitle = "Servidor no disponible"
            alertMessage = "Nuestro servidor no está disponible por el momento."
        default:
            break
        }
        
        func firstBlock(action: UIAlertAction) {
            self.logIn()
        }
        
        self.presentAlertWithTitle(alertTitle, withMessage: alertMessage, withButtonTitles: ["Reintentar", "OK"], withButtonStyles: [.Default, .Cancel], andButtonHandlers: [firstBlock, nil])
        print(response["error"])
    }
    
}
