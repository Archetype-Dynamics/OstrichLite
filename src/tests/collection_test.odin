package tests

import "core:fmt"
import "core:testing"
import "core:strings"
import "core:os"
import "../core/engine/data"
import lib "../library"
/********************************************************
Author: Marshall A Burns
GitHub: @SchoolyB
License: Apache License 2.0 (see LICENSE file for details)
Copyright (c) 2025-Present Archetype Dynamics, Inc.

File Description:
            Contains test procedures to ensure all procs in
            core/engine/data/collections.odin execute properly
*********************************************************/

@(test)
test_collection_creation :: proc(test: ^testing.T) {
    using lib
    using data
    using testing

    // Setup
    collectionName := "test_collection"
    collectionType:CollectionType= .STANDARD_PUBLIC
    collection := make_new_collection(collectionName, collectionType)
    defer free(collection)

    // Test collection creation
    testing.expect_value(test, collection.name, collectionName)
    testing.expect_value(test, collection.type, collectionType)
    testing.expect_value(test, collection.numberOfClusters, 0)

    // Test file creation
    success := create_collection_file(collection)
    testing.expect(test, success, "Failed to create collection file")

    // Verify collection exists
    exists := check_if_collection_exists(collection)
    testing.expect(test, exists, "Collection should exist after creation")

    // Cleanup
    collectionPath := concat_standard_collection_name(collection.name)
    defer delete(collectionPath)
    os.remove(collectionPath)
}

