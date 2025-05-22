package engine
import lib "../../library"
import "../server"

/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Marshall A Burns and Archetype Dynamics, Inc.

File Description:
            Contains logic for the OstrichLite engine
*********************************************************/

//The OstrichLite engine requires the server to be running
start_engine ::proc() -> int {
    using lib

    for {
        ostrichLiteEngine := new(OstrichLiteEngine)
        ostrichLiteEngine.Server.port = 8042
    }

    // free(ostrichLiteEngine)
    return 0
}