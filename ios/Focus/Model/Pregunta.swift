//
//  Pregunta.swift
//  Focus
//
//  Created by Eduardo Cristerna on 27/07/16.
//  Copyright © 2016 Eduardo Cristerna. All rights reserved.
//

import Foundation
import UIKit

enum TipoPregunta: Int {
    case Abierta = 1
    case Unica = 2
    case Multiple = 3
    case Ordenamiento = 4
}

class Pregunta {
    
    var id: Int
    var tipo: Int
    var numPregunta: Int
    var pregunta: String
    var video: String
    var imagen: UIImage? = nil
    var opciones: [String]
    var selectedOptions: [Bool] = [false, false, false, false, false, false, false, false, false, false]
    var respuesta: String = ""
    var nextOption: Int = 1
    var didSeeVideo: Bool
    
    init(id: Int, tipo: Int, numPregunta: Int, pregunta: String, video: String, imagen: String, opciones: [String]) {
        self.id = id
        self.tipo = tipo
        self.numPregunta = numPregunta
        self.pregunta = pregunta
        self.video = video
        self.didSeeVideo = self.video.isEmpty
        
        if let url = NSURL(string: Controller.imagesURL + imagen), data = NSData(contentsOfURL: url), image = UIImage(data: data) {
            self.imagen = image
        }
        
        self.opciones = opciones
    }
    
}
