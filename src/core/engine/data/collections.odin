package data

import lib "../../../library"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import "core:os"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            This file contains all the logic for interacting with
            collections within the OstrichLite engine.
*********************************************************/

//Reads over all standard collections, appends their names and returns them
//Dont forget to free the memery in the calling procedure
get_all_collection_names :: proc() -> [dynamic]string{
    using lib

    collectionArray:= make([dynamic]string, 0)
    standardCollectionDir, openDirError :=os.open(STANDARD_COLLECTION_PATH)

    collections, readDirError:= os.read_dir(standardCollectionDir, 1)
    for collection in collections{
        append(&collectionArray, collection.name)
    }

    return collectionArray
}

make_new_collection :: proc(name:string, type:lib.CollectionType) -> ^lib.Collection{
    using lib

    collection := new(lib.Collection)
    collection.name = name
    collection.type = type
    collection.numberOfClusters = 0
    collection.children = make([dynamic]Cluster)

    return collection
}