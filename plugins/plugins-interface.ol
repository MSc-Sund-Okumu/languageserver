/* MIT License
 *
 * Copyright (c) 2021 The Jolie Programming Language
 * Copyright (c) 2025 Anders Sund-Jensen <99sund@gmail.com>
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
 * Jolie types for the extensions to the language server
 */

/*
 * @author Kasper Okoyo Okumu & Anders Sund-Jensen
 */

from ast import Module


//type EventType: string( enum(["Service updated","Interface updated","..."]))

type Observer {
    //example: "socket://localhost:12345"
    locationString: string
    //eventType*: EventType
}

type WorkspaceModule {
    modules* {
        documentURI: string
        module: Module
    }
}

type ObserverStatus {
    status: int
    message: string
    currentState: string //TODO change this
}

type WorkSpaceFiles {
    fileURIs*: string 
}
/*
//This is in discussion
type NotificationMessage {
    //eventType: EventType
    workspace: WorkspaceModule
}
*/
interface RefactoringsInterface {
    RequestResponse:
        parseWorkspace(void)(WorkspaceModule)
 }

interface ObserverInterface {
    RequestResponse:
        addObserver(Observer)(WorkspaceModule),
        removeObserver(Observer)(ObserverStatus)
    OneWay:
        //sends a NotificationMessage of to all observers
        notify(void)
}

interface ObserverUtilsInterface {
    RequestResponse:
        parseWorkspace(void)(WorkspaceModule)
}

interface NotificationInterface {
    OneWay:
        update(WorkspaceModule)
}

 