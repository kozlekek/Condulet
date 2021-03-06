//
//  ServiceTaskBuilding+Response.swift
//  Forest
//
//  Created by Natan Zalkin on 29/09/2018.
//  Copyright © 2018 Natan Zalkin. All rights reserved.
//

/*
 *
 * Copyright (c) 2018 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

import Foundation

// MARK: - Cancellation

public extension ServiceTaskBuilding {
    
    /// Set cancellation handler
    @discardableResult
    func cancellation(_ handler: ServiceTaskCancellationHandling) -> Self {
        cancellationHandler = handler
        return self
    }
    
    /// Handle cancellation with block
    @discardableResult
    func cancellation(_ handler: @escaping () -> Void) -> Self {
        cancellationHandler = BlockCancellationHandler { [queue = responseQueue] in
            queue.addOperation {
                handler()
            }
        }
        return self
    }
}

// MARK: - Error handlers

public extension ServiceTaskBuilding {

    /// Set error handler
    @discardableResult
    func error(_ handler: ServiceTaskErrorHandling) -> Self {
        errorHandler = handler
        return self
    }
    
    /// Handle error with block
    @discardableResult
    func error(_ handler: @escaping (Error, URLResponse?) -> Void) -> Self {
        errorHandler = BlockErrorHandler { [queue = responseQueue] (error, response) in
            queue.addOperation {
                handler(error, response)
            }
        }
        return self
    }

}

// MARK: - Response handlers expecting specific type of response data

public extension ServiceTaskBuilding {
    
    /// Set response handler
    @discardableResult
    func response(_ handler: ServiceTaskResponseHandling) -> Self {
        responseHandler = handler
        return self
    }

    /// Handle HTTP status response
    @discardableResult
    func statusCode(_ handler: @escaping (Int) -> Void) -> Self {
        responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            
            guard let response = response as? HTTPURLResponse else {
                throw ServiceTaskError.invalidResponse
            }
            
            queue.addOperation {
                handler(response.statusCode)
            }
        }
        return self
    }
    
    /// Handle response with block
    @discardableResult
    func content(_ handler: @escaping (ServiceTaskContent, URLResponse) -> Void) -> Self {
        responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            queue.addOperation {
                handler(content, response)
            }
        }
        return self
    }
    
    /// Handle file response for tasks performed via Download action. Returned file should be removed manually after use. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func file(_ handler: @escaping (URL, URLResponse) -> Void) -> Self {
        responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            switch content {
            case .file(let url):
                queue.addOperation {
                    handler(url, response)
                }
            default:
                throw ServiceTaskError.invalidContent
            }
        }
        return self
    }
    
    /// Handle data response
    @discardableResult
    func data(_ handler: @escaping (Data, URLResponse) -> Void) -> Self {
        responseHandler = BlockResponseHandler { [queue = responseQueue] (content, response) in
            switch content {
            case .data(let data):
                queue.addOperation {
                    handler(data, response)
                }
            case .file:
                throw ServiceTaskError.invalidContent
            }
        }
        return self
    }


    /// Handle text response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func text(_ handler: @escaping (String, URLResponse) -> Void) -> Self {
        responseHandler = TextContentHandler { [queue = responseQueue] (string, response) in
            queue.addOperation {
                handler(string, response)
            }
        }
        return self
    }

    /// Handle json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func json(_ handler: @escaping (Any, URLResponse) -> Void) -> Self {
        responseHandler = JSONContentHandler { [queue = responseQueue] (object, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }
    
    /// Handle json dictionary response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func array(_ handler: @escaping ([Any], URLResponse) -> Void) -> Self {
        responseHandler = JSONContentHandler { [queue = responseQueue] (object, response) in
            guard let array = object as? [Any] else {
                throw ServiceTaskError.invalidContent
            }
            queue.addOperation {
                handler(array, response)
            }
        }
        return self
    }
    
    /// Handle json dictionary response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func dictionary(_ handler: @escaping ([AnyHashable: Any], URLResponse) -> Void) -> Self {
        responseHandler = JSONContentHandler { [queue = responseQueue] (object, response) in
            guard let dictionary = object as? [AnyHashable: Any] else {
                throw ServiceTaskError.invalidContent
            }
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }
    
    /// Handle url-encoded response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func urlencoded(_ handler: @escaping ([String: String], URLResponse) -> Void) -> Self {
        responseHandler = URLEncodedContentHandler { [queue = responseQueue] (dictionary, response) in
            queue.addOperation {
                handler(dictionary, response)
            }
        }
        return self
    }
    
    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func codable<T: Decodable>(_ handler: @escaping (T, URLResponse) -> Void) -> Self {
        responseHandler = DecodableContentHandler { [queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func codable<T: Decodable>(_ type: T.Type, handler: @escaping (T, URLResponse) -> Void) -> Self {
        responseHandler = DecodableContentHandler { [queue = responseQueue] (object: T, response) in
            queue.addOperation {
                handler(object, response)
            }
        }
        return self
    }

}

// MARK: - Encapsulated response handlers

public typealias ServiceTaskResult<T> = Result<T, Error>

public extension ServiceTaskBuilding {

    /// Handle HTTP status response with block
    @discardableResult
    func response(statusCode handler: @escaping (ServiceTaskResult<Int>) -> Void) -> Self {
        statusCode { (status) in
            handler(.success(status))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }
    
    /// Handle response with block
    @discardableResult
    func response(content handler: @escaping (ServiceTaskResult<ServiceTaskContent>) -> Void) -> Self {
        content { (content, response) in
            handler(.success(content))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }
    
    /// Handle file response for tasks performed via Download action. Returned file should be removed manually after use. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response(file handler: @escaping (ServiceTaskResult<URL>) -> Void) -> Self {
        file { (url, response) in
            handler(.success(url))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }


    /// Handle data response. When task is performed via Download action, received file content will be handled as data response
    @discardableResult
    func response(data handler: @escaping (ServiceTaskResult<Data>) -> Void) -> Self {
        data { (data, response) in
            handler(.success(data))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }
    
    /// Handle text response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response(text handler: @escaping (ServiceTaskResult<String>) -> Void) -> Self {
        text { (string, response) in
            handler(.success(string))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }

    /// Handle json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response(json handler: @escaping (ServiceTaskResult<Any>) -> Void) -> Self {
        json { (object, response) in
            handler(.success(object))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }

    /// Handle array json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response(array handler: @escaping (ServiceTaskResult<[Any]>) -> Void) -> Self {
        array { (object, response) in
            handler(.success(object))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }
    
    /// Handle dictionary json response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response(dictionary handler: @escaping (ServiceTaskResult<[AnyHashable: Any]>) -> Void) -> Self {
        dictionary { (object, response) in
            handler(.success(object))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }
    
    /// Handle url-encoded response. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response(urlencoded handler: @escaping (ServiceTaskResult<[String: String]>) -> Void) -> Self {
        urlencoded { (dictionary, response) in
            handler(.success(dictionary))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }

    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response<T: Decodable>(codable type: T.Type, handler: @escaping (ServiceTaskResult<T>) -> Void) -> Self {
        codable { (object, response) in
            handler(.success(object))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }

    /// Handle json response with serialized Decodable object of infered type. When received response of other type task will fail with ServiceTaskError.invalidResponse
    @discardableResult
    func response<T: Decodable>(codable handler: @escaping (ServiceTaskResult<T>) -> Void) -> Self {
        codable { (object, response) in
            handler(.success(object))
        }
        error { (error, response) in
            handler(.failure(error))
        }
        return self
    }

}
