from console import Console

service CodeActions {
    execution: concurrent
    embed Console as Console

    inputPort CodeActionInput {
		location: "local"
		interfaces: WorkspaceInterface
	}
    main {

    }
}