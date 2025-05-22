package server

import lib"../../library"
import "core:time"
import "core:math/rand"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains logic for server session information tracking
*********************************************************/

//Ceate and return a new server session, sets default session info. takes in the current user
@(cold, require_results)
make_new_server_session ::proc(user: ^lib.User) -> ^lib.ServerSession{
    using lib
    newSession := new(ServerSession)
	newSession.Id  = rand.int63_max(1e16 + 1)
    newSession.start_timestamp = time.now()
    //newSession.end_timestamp is set when the kill switch is activated or server loop ends
    newSession.user = user^

    free(user)
    return newSession
}

//Checks if the current server session duration has met the max session time, returns true if it has
@(require_results)
check_id_server_session_limi_met :: proc(session: ^lib.ServerSession) ->(maxDurationMet: bool){
    maxDurationMet = false
    if session.total_runtime >= lib.MAX_SESSION_TIME{
        maxDurationMet = true
    }
    return maxDurationMet
}
