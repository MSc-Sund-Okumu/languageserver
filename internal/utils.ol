from console import Console
from string_utils import StringUtils
from runtime import Runtime
from file import File
from inspector import Inspector

from ..lsp import UtilsInterface, ServerToClient

constants {
	INTEGER_MAX_VALUE = 2147483647
}

/*
 * The main aim of this service is to keep saved
 * in global.textDocument all open documents
 * and keep them updated. The type of global.textDocument
 * is TextDocument and it is defined in types/lsp.iol
 */
service Utils {
	execution: sequential

	embed Inspector as Inspector
	embed Console as Console
	embed StringUtils as StringUtils
	embed Runtime as Runtime
	embed File as File

	inputPort Utils {
		location: "local://Utils"
		interfaces: UtilsInterface
	}
	
	outputPort LanguageClient {
		location: "local://Client"
		interfaces: ServerToClient
	}

	// TODO: refactor this definition to a functional service
	define inspect {
		scope( inspection ) {
			saveProgram = true
			install( default =>
				stderr = inspection.(inspection.default)
				stderr.regex =  "\\s*(.+):\\s*(\\d+):\\s*(error|warning)\\s*:\\s*(.+)"
				find@StringUtils( stderr )( matchRes )
				// //getting the uri of the document to be checked
				//have to do this because the inspector, when returning an error,
				//returns an uri that looks the following:
				// /home/eferos93/.atom/packages/Jolie-ide-atom/server/file:/home/eferos93/.atom/packages/Jolie-ide-atom/server/utils.ol
				//same was with jolie --check
				if ( !(matchRes.group[1] instanceof string) ) {
					matchRes.group[1] = ""
				}
				indexOf@StringUtils( matchRes.group[1] {
					word = "file:"
				} )( indexOfRes )
				if ( indexOfRes > -1 ) {
					subStrReq = matchRes.group[1]
					subStrReq.begin = indexOfRes + 5

					substring@StringUtils( subStrReq )( documentUri ) //line
				} else {
					replaceRequest = matchRes.group[1]
					replaceRequest.regex = "\\\\";
					replaceRequest.replacement = "/"
					replaceAll@StringUtils( replaceRequest )( documentUri )
					// documentUri = "///" + fileName
				}
				
				//line
				l = int( matchRes.group[2] )
				//severity
				sev -> matchRes.group[3]
				//TODO alwayes return error, never happend to get a warning
				//but this a problem of the jolie parser
				if ( sev == "error" ) {
					s = 1
				} else {
					s = 1
				}

				diagnosticParams << {
					uri = "file:" + documentUri
					diagnostics << {
					range << {
						start << {
						line = l-1
						character = 1
						}
						end << {
						line = l-1
						character = INTEGER_MAX_VALUE
						}
					}
					severity = s
					source = "jolie"
					message = matchRes.group[4]
					}
				}
				publishDiagnostics@LanguageClient( diagnosticParams )
				saveProgram = false
			)

			// TODO : fix these:
			// - remove the directories of this LSP
			// - add the directory of the open file.
			getenv@Runtime( "JOLIE_HOME" )( jHome )
			getFileSeparator@File()( fs )
			getParentPath@File( uri )( documentPath )
			regexRequest = uri
			regexRequest.regex =  "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
			find@StringUtils( regexRequest )( regexResponse ) 
			inspectionReq << {
				filename = regexResponse.group[5]
				source = docText
				includePaths[0] = jHome + fs + "include"
				includePaths[1] = documentPath
			}
			replacementRequest = regexResponse.group[5]
			replacementRequest.regex = "%20"
			replacementRequest.replacement = " "
			replaceAll@StringUtils(replacementRequest)(inspectionReq.filename)

			replacementRequest = inspectionReq.includePaths[1]
			replaceAll@StringUtils(replacementRequest)(inspectionReq.includePaths[1])
			inspectPorts@Inspector( inspectionReq )( inspectionRes )
		}
	}

	// TODO: refactor this definition to an internal service
	define sendDiagnostics {
		if ( saveProgram ) {
			doc.jolieProgram << inspectionRes
			diagnosticParams << {
			uri = uri
			diagnostics = void
			}
			publishDiagnostics@LanguageClient( diagnosticParams )
		}
	}

	init {
		println@Console( "Utils Service started at " + global.inputPorts.Utils.location + ", connected to " + LanguageClient.location )(  )
	}

	main {
		[ insertNewDocument( newDoc ) ] {
			docText -> newDoc.textDocument.text
			uri -> newDoc.textDocument.uri
			version -> newDoc.textDocument.version
			splitReq = docText
			splitReq.regex = "\n"
			split@StringUtils( splitReq )( splitRes )
			for ( line in splitRes.result ) {
				doc.lines[#doc.lines] = line
			}

			inspect

			sendDiagnostics

			doc << {
				uri = uri
				source = docText
				version = version
			}

			println@Console( "Insert new document: " + doc.uri )()

			// TODO: use a dictionary with URIs as keys instead of an array
			global.textDocument[#global.textDocument] << doc
		}

		[ updateDocument( txtDocModifications ) ] {
			docText -> txtDocModifications.text
			uri -> txtDocModifications.uri
			newVersion -> txtDocModifications.version
			docsSaved -> global.textDocument
			found = false
			for ( i = 0, i < #docsSaved && !found, i++ ) {
				if ( docsSaved[i].uri == uri ) {
					found = true
					indexDoc = i
				}
			}
			//TODO is found == false, throw ex (should never happen though)
			if ( found && docsSaved[indexDoc].version < newVersion ) {
				splitReq = docText
				splitReq.regex = "\n"
				split@StringUtils( splitReq )( splitRes )
				for ( line in splitRes.result ) {
					doc.lines[#doc.lines] = line
				}

				inspect

				sendDiagnostics

				doc << {
					source = docText
					version = newVersion
				}

				docsSaved[indexDoc] << doc
			} else {
				inspect

				sendDiagnostics
			}
		}

		[ deleteDocument( txtDocParams ) ] {
			uri -> txtDocParams.textDocument.uri
			docsSaved -> global.textDocument
			keepRunning = true
			for ( i = 0, i < #docsSaved && keepRunning, i++ ) {
				if ( uri == docsSaved[i].uri ) {
				undef( docsSaved[i] )
				keepRunning = false
				}
			}
		}

		[ getDocument( uri )( txtDocument ) {
			docsSaved -> global.textDocument
			found = false
			for ( i = 0, i < #docsSaved && !found, i++ ) {
				println@Console( " Checking " + docsSaved[i].uri )()
				if ( docsSaved[i].uri == uri ) {
					txtDocument << docsSaved[i]
					found = true
				}
			}

			if ( !found ) {
				//TODO if found == false throw exception
				println@Console( "Doc not found: " + uri )()
			}
		} ]
	}
}
