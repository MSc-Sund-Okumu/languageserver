from ..lsp import GlobalVariables
from console import Console
from file import File
from ast import Ast
from string-utils import StringUtils
from .plugins-interface import ObserverUtilsInterface

service ObserverUtils {
    embed Console as Console
    embed StringUtils as StringUtils
    embed File as File
    embed Ast as Ast

    outputPort GlobalVar {
            location: "local://GlobalVar"
            interfaces: GlobalVariables
        }
    
    inputPort ObserverUtilsPort {
        location: "local"
        interfaces: ObserverUtilsInterface
    }

    main {
        [parseWorkspace()(response) {
            //Parse all modules                
            getRootUri@GlobalVar()(rootURI)

            println@Console("rootURI: " + rootURI)()

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
                recursive = true
                info = true
            }
            
            list@File(listReq)(listResp)

            for(jolieFile in listResp.result) {
                
                if (fileSeparator == "\\") {
                    replaceRequest << jolieFile.info.absolutePath {
                    regex = "\\\\"
                    replacement = "/"
                    }
                    replaceAll@StringUtils(replaceRequest)(jolieFile.info.absolutePath)
                    replaceRequest << jolieFile.info.absolutePath {
                    regex = " "
                    replacement = "%20"
                    }
                    replaceAll@StringUtils(replaceRequest)(jolieFile.info.absolutePath)
                    uriPath = "file:///" + jolieFile.info.absolutePath
                } else {
                    uriPath = "file://" + jolieFile.info.absolutePath
                }
                
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
            response.modules << modules
        }]
    }
}