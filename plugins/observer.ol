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
from .observerUtils import ObserverUtils

from vectors import Vectors
from console import Console
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

    

    outputPort NotificationPort {
        // set location dynamically
        protocol: http {
            .format = "json"
        }
        interfaces: NotificationInterface
    }
    embed ObserverUtils as ObserverUtils
    embed Vectors as Vectors
    embed Console as Console
    embed StringUtils as StringUtils
    
    main {
        [notify()] {
            println@Console("inside notify")()
            valueToPrettyString@StringUtils(global.observers)(pretty)
            println@Console(pretty)()
            
            if(#global.observers.items > 0) {
                
                parseWorkspace@ObserverUtils()(notification)
                
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

        [addObserver(Observer)(workspace) {
            //consider checking for duplicates, or merging subscriber.event
            //critical section, ensure synchronization if using concurrent execution
            addRequest << {
                item << Observer
                vector = global.observers
            }
            //valueToPrettyString@StringUtils(addRequest)(pretty)
            //println@Console(pretty)()
            add@Vectors(addRequest)(newObservers)
            //TODO check if Observer is not already in global.observers to pre
            global.observers << newObservers
            //valueToPrettyString@StringUtils(global.observers)(pretty)
            //println@Console(pretty)()

            //send current state to the new observer
            parseWorkspace@ObserverUtils()(workspace)
           
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
