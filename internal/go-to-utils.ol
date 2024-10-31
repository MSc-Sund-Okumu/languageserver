from console import Console
from ..lsp import GotoUtilsInterface

service GotoUtils {
    execution: concurrent
    embed Console as Console

    inputPort GotoUtilsInput {
		location: "local://GotoUtils"
		interfaces: GotoUtilsInterface
	}
    
    main {
        [typeDefinition(typeDefinitionParams)(typeDefinitionResponse){
            println@Console("inside typeDefinition")()
        }]
    }
}