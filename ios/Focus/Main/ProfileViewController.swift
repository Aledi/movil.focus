//
//  ProfileViewController.swift
//  Focus
//
//  Created by Eduardo Cristerna on 30/07/16.
//  Copyright © 2016 Eduardo Cristerna. All rights reserved.
//

import UIKit
import MessageUI

enum Sections: Int {
    case User
    case Panels
    case Help
    case Other
    case LogOut
}

let phoneNumber: String = "+528183387258"
let email: String = "atencion@focuscg.com.mx"

class ProfileViewController: UITableViewController, UIActivityItemSource, MFMailComposeViewControllerDelegate {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var panelsLabel: UILabel!
    @IBOutlet var encuestasLabel: UILabel!
    
    var loadingAlert: UIAlertController?
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Lifecycle
    // -----------------------------------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
        
        guard let user = User.currentUser, paneles = self.appDelegate.paneles else {
            return
        }
        
        var pending = 0
        
        for panel in paneles {
            pending += panel.encuestasPendientes
        }
        
        self.nameLabel.text = user.nombre
        self.emailLabel.text = user.email
        self.panelsLabel.text = "\(paneles.count)"
        self.encuestasLabel.text = "\(pending)"
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Navigation
    // -----------------------------------------------------------------------------------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if (segue.identifier == "logOut") {
            NSUserDefaults.removeUserDefaults()
            self.appDelegate.user = nil
        } else if (segue.identifier == "showHistorial") {
            let historialViewController = segue.destinationViewController as! HistorialViewController
            historialViewController.data = sender as! [Historial]
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - TableView
    // -----------------------------------------------------------------------------------------------------------
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch Sections(rawValue: indexPath.section)! {
        case .Panels:
            if (indexPath.row == 2) {
                self.downloadHistory()
            }
        case .Help:
            if (indexPath.row == 1) {
                self.sendEmail()
            } else if (indexPath.row == 2) {
                self.call()
            }
            
            return
        case .Other:
            if (indexPath.row == 0) {
                self.shareApp()
            } else if (indexPath.row == 1) {
                self.rateApp()
            }
        case .LogOut:
            func firstBlock(action: UIAlertAction) {
                Controller.requestForAction(.UNREGISTER_DEVICE, withParameters: ["id" : User.currentUser!.id], withSuccessHandler: nil, andErrorHandler: nil)
                self.performSegueWithIdentifier("logOut", sender: nil)
            }
            
            self.presentAlertWithTitle("Cerrar Sesión", withMessage: "La próxima vez que abra la aplicación se le pedirán sus datos de acceso.", withButtonTitles: ["Cancelar", "Cerrar"], withButtonStyles: [.Cancel, .Destructive], andButtonHandlers: [nil, firstBlock])
            
            return
        default:
            return
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Helpers
    // -----------------------------------------------------------------------------------------------------------
    
    func call() {
        if let phoneURL: NSURL = NSURL(string: "tel://\(phoneNumber)") {
            if (UIApplication.sharedApplication().canOpenURL(phoneURL)) {
                UIApplication.sharedApplication().openURL(phoneURL)
            }
        }
    }
    
    func sendEmail() {
        let mailComposeViewController = self.mailComposerViewController()
        
        if (MFMailComposeViewController.canSendMail()) {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        self.presentAlertWithTitle("Error", withMessage: "Su dispositivo parece no estar configurado para enviar correo.", withButtonTitles: ["OK"], withButtonStyles: [.Cancel], andButtonHandlers: [nil])
    }
    
    func mailComposerViewController() -> MFMailComposeViewController {
        let user = self.appDelegate.user!
        let mailComposerViewController = MFMailComposeViewController()
        
        mailComposerViewController.mailComposeDelegate = self
        mailComposerViewController.setToRecipients([email])
        mailComposerViewController.setSubject("Soporte Aplicación Móvil")
        mailComposerViewController.setMessageBody("\n\n\n\nUsuario: \(user.username)\nID: \(user.id)\nCorreo: \(user.email)", isHTML: false)
        
        return mailComposerViewController
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - History
    // -----------------------------------------------------------------------------------------------------------
    
    func downloadHistory() {
        self.loadingAlert = self.presentAlertWithTitle("Cargando", withMessage: nil, withButtonTitles: [], withButtonStyles: [], andButtonHandlers: [])
        Controller.requestForAction(.GET_HISTORY, withParameters: ["panelista" : "\(User.currentUser!.id)"], withSuccessHandler: self.successHandler, andErrorHandler: self.errorHandler)
    }
    
    func successHandler(response: NSDictionary) {
        self.loadingAlert?.dismissViewControllerAnimated(true, completion: {
            var data: [Historial] = []
            
            if (response["status"] as? String == "SUCCESS") {
                if let results = response["results"] as? [AnyObject] {
                    for object in results {
                        let history = object as! NSDictionary
                        data.append(Historial(nombrePanel: history["nombrePanel"] as! String, fechaIniPanel: history["fechaInicioPanel"] as? String, fechaFinPanel: history["fechaFinPanel"] as? String, nombreEncuesta: history["nombreEncuesta"] as! String, fechaIniEncuesta: history["fechaInicioEncuesta"] as? String, fechaFinEncuesta: history["fechaFinEncuesta"] as? String, fechaRespuesta: history["fechaRespuesta"] as? String, horaRespuesta: history["horaRespuesta"] as? String))
                    }
                    
                    self.performSegueWithIdentifier("showHistorial", sender: data)
                    return
                }
            }
            
            self.presentAlertWithTitle("Error", withMessage: "No hemos podido cargar los datos.", withButtonTitles: ["OK"], withButtonStyles: [.Cancel], andButtonHandlers: [nil])
        })
    }
    
    func errorHandler(response: NSDictionary) {
        self.loadingAlert?.dismissViewControllerAnimated(true, completion: {
            var alertTitle = ""
            var alertMessage = ""
            
            switch (response["error"] as! NSError).code {
            case -1009:
                alertTitle = "Sin conexión a internet"
                alertMessage = "Para utilizar la aplicación, su dispositivo debe estar conectado a internet."
            default:
                alertTitle = "Servidor no disponible"
                alertMessage = "Nuestro servidor no está disponible por el momento."
            }
            
            self.presentAlertWithTitle(alertTitle, withMessage: alertMessage, withButtonTitles: ["OK"], withButtonStyles: [.Cancel], andButtonHandlers: [nil])
            print(response["error"])
        })
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - MFMailComposeViewControllerDelegate
    // -----------------------------------------------------------------------------------------------------------
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // -----------------------------------------------------------------------------------------------------------
    // MARK: - Share/Rate App
    // -----------------------------------------------------------------------------------------------------------
    
    func shareApp() {
        let activityController = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        if #available(iOS 9.0, *) {
            let excludedActivityTypes = [
                UIActivityTypePrint,
                UIActivityTypeCopyToPasteboard,
                UIActivityTypeAssignToContact,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo,
                UIActivityTypePostToTencentWeibo,
                UIActivityTypeOpenInIBooks
            ]
            
            activityController.excludedActivityTypes = excludedActivityTypes
        }
        
        self.presentViewController(activityController, animated: true, completion: nil)
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return ""
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        return "¡Dale un vistazo a la aplicación de Focus!\n\nhttps://itunes.apple.com/us/app/focus/id1156729510?ls=1&mt=8"
    }
    
    func activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
        return "Focus"
    }
    
    func rateApp() {
        UIApplication.sharedApplication().openURL(NSURL(string: "itms-apps://itunes.apple.com/app/id1156729510")!)
    }
    
}
