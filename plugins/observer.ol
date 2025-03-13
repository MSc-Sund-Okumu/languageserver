/* MIT License
 *
 * Copyright (c) 2021 The Jolie Programming Language
 * Copyright (C) 2025 Kasper Okoyo Okumu <kaspokumu@gmail.com>
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
 * SOFTWARE.from console import Console
 */

/*
 * Implementation of the subject side of the Observer pattern.
 */

/*
 * @author Kasper Okoyo Okumu
 */
from .plugins-interface import ObserverInterface, NotificationInterface
from ..lsp import GlobalVariables
from vectors import Vectors
from console import Console
from file import File
from ast import Ast
from string-utils import StringUtils

service ObserverSubject {
    execution: sequential
    inputPort ObserverManagementPort {
        location: "socket://localhost:12345"//TODO
        protocol: http {
            format = "json"
        }
        interfaces: ObserverInterface
    }

    inputPort ObserverInput {
		location: "local://Plugins/Observer"
		interfaces: ObserverInterface
	}

    outputPort GlobalVar {
		location: "local://GlobalVar"
		interfaces: GlobalVariables
	}

    outputPort NotificationPort {
        // set location dynamically
        protocol: http {
            .format = "json"
        }
        interfaces: NotificationInterface
    }

    embed Vectors as Vectors
    embed Console as Console
    embed StringUtils as StringUtils
    embed File as File
    embed Ast as Ast
    

    main {
        [notify()] {
            println@Console("inside notify")()
            valueToPrettyString@StringUtils(global.observers)(pretty)
            println@Console(pretty)()
            
            if(#global.observers.items > 0) {
                //Parse all modules
                println@Console("rootURI: " + rootURI)()
                
                getRootUri@GlobalVar()(rootURI)
                //remove leading "file://" using replaceFirst
                replaceRequest << rootURI {
                    regex = "file://"
                    replacement = ""
                }
                replaceFirst@StringUtils(replaceRequest)(rootURI)

                //Change encoding of spaces from "%20" to " "
                replaceRequest << rootURI {
                    regex = "%20"
                    replacement = " "
                }
                replaceAll@StringUtils(replaceRequest)(rootURI)
                
                //Windows fix 
                getFileSeparator@File()(fileSeparator)
                if(fileSeparator == "\\") {
                    //remove the first / "/c:/something/" -> c:/something/"
                    replaceRequest << rootURI {
                    regex = "/"
                    replacement = ""
                    }
                    replaceFirst@StringUtils(replaceRequest)(rootURI)
                    //remove the first / "/c:/something/" -> c:/something/"
                    
                    replaceRequest << rootURI {
                    regex = "/"
                    replacement = "\\\\"
                    }
                    replaceAll@StringUtils(replaceRequest)(rootURI)
                    
                }
                listReq << {
                    regex = ".*\\.[oO][lL]$"
                    directory = rootURI
                    recursive = false
                    info = true
                }

                list@File(listReq)(listResp)
                for(jolieFile in listResp.result) {
                    uriPath = "file://" + jolieFile.info.absolutePath
                    println@Console("parsing: " + uriPath)()
                    parseModule@Ast(uriPath)(module)
                    // insert uriPath & module in aWorkspaceModule and send to all observers
                    
                    modules[#modules] << {
                        documentURI = uriPath
                        module << module
                    }
                    valueToPrettyString@StringUtils(module)(pretty)
                    println@Console(pretty)()
                }
                
                notification << {
                    modules << modules
                }
                // send the notification to observers
                for(observer in global.observers.items) {
                    println@Console("inside notify for-loop")()
                    println@Console(observer.locationString)()
                    
                    NotificationPort.location = observer.locationString
    
                    update@NotificationPort(notification)
                    
                }
                undef(NotificationPort.location)

            }
            
        }

        [addObserver(Observer)(observerStatus) {
            //consider checking for duplicates, or merging subscriber.event
            //critical section, ensure synchronization if using concurrent execution
            addRequest << {
                item << Observer
                vector = global.observers
            }
            //valueToPrettyString@StringUtils(addRequest)(pretty)
            //println@Console(pretty)()
            add@Vectors(addRequest)(newObservers)

            global.observers << newObservers
            //valueToPrettyString@StringUtils(global.observers)(pretty)
            //println@Console(pretty)()
            observerStatus << {
                status = 42 //TODO what is this??
                message = "added Observer" 
                currentState = " " //TODO what is this??
            }
        }]

        [removeObserver(removeRequest)(observerStatus) {
            locationStringToRemove = removeRequest.locationString
            println@Console("inside removeObserver,")()

            
            //critical section, ensure synchronization if using concurrent execution
            //Vector has no remove operation, so instead we make a new vector, skipping the old elements to be removed
            for(observer in global.observers.items) {
                println@Console("observer.locationString " + observer.locationString)()
                if (observer.locationString != locationStringToRemove) {
                    addRequest = {
                        item << Observer
                        vector = newObservers
                    }
                    add@Vectors(addRequest)(newObservers)
                }
            }
            println@Console("observers " + global.observers)()

            global.observers << newObservers
            observerStatus << {
                status = 42 //TODO what is this??
                message = "removed Observer" 
                currentState = " " //TODO what is this??
            }

        }]

    }

}