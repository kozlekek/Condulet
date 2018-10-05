//
//  ServiceTaskInterception.swift
//  Condulet
//
//  Created by Natan Zalkin on 05/10/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

import Foundation


public protocol ServiceTaskInterception {

    /// Modify request before assigning it to URLSessionTask. Throwing error will cause the task to fail with provided error
    func serviceTask(_ task: ServiceTask, modify request: inout URLRequest) throws

    /// Intercept response handling. Return true to disable checking of valid HTTP status. Throwing error will cause the task to fail with provided error
    func serviceTask(_ task: ServiceTask, intercept respone: URLResponse?) throws -> Bool

    /// Intercept content handling. By returning true you become responsible to call apropriate responseHandler callbacks. Throwing error will cause the task to fail with provided error
    func serviceTask(_ task: ServiceTask, intercept content: ServiceTask.Content?) throws -> Bool
    
    /// Intercept error handling. By returning true you become responsible to call apropriate errorHandler callbacks
    func serviceTask(_ task: ServiceTask, intercept error: Error) -> Bool

}