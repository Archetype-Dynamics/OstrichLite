package engine
import lib "../../lib"

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

    ostrichLiteEngine := new(OstrichLiteEngine)
    ostrichLiteEngine.server.port = 8042

    free(ostrichLiteEngine)
    return 0
}