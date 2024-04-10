//
//  APIConstants.swift
//  Climance
//
//  Created by Liellison Menezes on 09/04/24.
//

import Foundation

#if LOCAL
    let baseUrl = "https://api.hgbrasil.com/weather"
#elseif DEVELOP
    let baseUrl = "https://api.hgbrasil.com/weather"
#elseif TEST
    let baseUrl = "https://api.hgbrasil.com/weather"
#else
    let baseUrl = "https://api.hgbrasil.com/weather"
#endif

private var apiKey = "?key=YOU-KEY"

var ConditionsUrl: String {
    return baseUrl + "/icons/conditions"
}

var MoonUrl: String {
    return baseUrl + "/icons/moon"
}
