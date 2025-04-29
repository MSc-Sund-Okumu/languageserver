from ..lsp import WorkspaceEdit, Range, Location

type AddInterfaceParam {
    module: string
    interfaceName: string
}

type IsInsideParam {
    inner: Range | Location
    outer: Range | Location
}

interface EditUtilsInter {
    requestResponse:
        addInterface(void)(WorkspaceEdit)
        isInside(IsInsideParam)(bool)
}

service EditUtils {
    execution: concurrent
    inputPort Input {
        location: "local"
        interfaces: EditUtilsInter
    }
    main {
        [addInterface(addInterfaceParam)(edit) {
            beginningOfFile << {
                line = 0
                character = 0
			}
			beginningRange << {
                start << beginningOfFile
                end << beginningOfFile
			}
            annotationId = new
            edit << {
                documentChanges[0] << {
                    textDocument << {
                        uri = addInterfaceParam.module
                        //version = void
                    }
                    edits[0] << {
                        range << beginningRange
                        newText = "interface " + addInterfaceParam.interfaceName + " {\n}"
                        annotationId = annotationId
                    }
                    //dummy edit to force jolie to make edits a json list
                    edits[1] << {
                        range << beginningRange
                        newText = ""
                    }
                }
                changeAnnotations.(annotationId) << {
                    label = "Create new interface"
                    needsConfirmation = false
                    description = "Create a new empty interface at the top of the module"
                }
            }
        }]

        [isInside(request)(result) {
            outer <- request.outer
            inner <- request.inner

            if(inner instanceof Location && !(outer instanceof Location)) {
                throw "inner and outer must be the same type"
            }
            validURI = true
            if(inner instanceof Location) {
                if(inner.uri == outer.uri) {
                    //hope you can reassign like this
                    outer <- request.outer.range
                    inner <- request.inner.range
                } else {
                    validURI = false
                }
            } 

            validLine = false
            if(inner.start.line >= outer.start.line) {
                if(inner.end.line <= outer.end.line) {
                    //inner starts after outer and ends before outer ends
                    validLine = true
                }
            }

            validChar = true
            if(inner.start.line == outer.start.line) {
                //we only need to test the start character if inner and outer start on the same line
                if(inner.start.character < outer.start.character){
                    //inner starts before outer
                    validChar = false
                }
            }
            if(inner.end.line == outer.end.line) {
                if(inner.end.character > outer.end.character){
                    validChar = false
                }
            }

            result = validLine && validChar && validURI
        }]

        /*
        [disembed(disembedParam)(edit) {
            beginningOfFile << {
                line = 0
                character = 0
			}
			beginningRange << {
                start << beginningOfFile
                end << beginningOfFile
			}

            edit << {
                documentChanges[0] << {
                    textDocument << {
                        uri = disembedParam.module
                        //version = void
                    }
                    edits[0] << {
                        range << disembedParam.range
                        newText = "outputPort {" 
                        + "//location: insert the location to the disembedded service here\n"
                        + "interfaces: " + serviceInterface + "\n"
                        + "protocol: " + newProtocol + "\n"
                        + "}" 
                        annotationId = new
                    }
                    
                    edits[1] << {
                        range << beginningRange
                        newText = "from " + pathToInterface + " import " + InterfaceName + "\n"
                    }
                }
                changeAnnotations.(annotationId) << {
                    label = "Disembed an embedded service"
                    needsConfirmation = false
                    description = ""
                }
            }
        }]
        */
    }
}