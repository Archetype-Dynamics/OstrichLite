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
            Contains test procedures to ensure procs in
            core/engine/data/collections.odin execute properly
*********************************************************/

@(test)
test_cluster_creation :: proc(test: ^testing.T) {
    using lib
    using data
    using testing

    // Setup
    collectionName := "test_collection"
    collectionType:CollectionType= .STANDARD_PUBLIC
    collection := make_new_collection(collectionName, collectionType)
    defer free(collection)

    clusterName:= "test_cluster"
    cluster:= make_new_cluster(collection, clusterName)
    cluster.parent = collection^
    cluster.id = 0123456789
    defer free(cluster)

    // Test collection creation
    testing.expect_value(test, collection.name, collectionName)
    testing.expect_value(test, collection.type, collectionType)
    testing.expect_value(test, collection.numberOfClusters, 0)

    // create the collection
    collectionCreationSuccess := create_collection_file(collection)
    testing.expect(test, collectionCreationSuccess, "Failed to create collection file")

    // Verify collection exists
   collectionExists := check_if_collection_exists(collection)
   testing.expect(test,collectionExists, "Collection should exist after creation")

    //create the cluster block
    clusterCreationSuccess:= create_cluster_block_in_collection(collection, cluster)
    testing.expect(test, clusterCreationSuccess, "Failed to create cluster block within collection")

    //verify the a the cluster exists within the collection
    clusterExists:= check_if_cluster_exsists_in_collection(collection, cluster)
    testing.expect(test, clusterExists, "Cluster should exist within collection after creation")

    // Cleanup just remove the collection
    collectionPath := concat_standard_collection_name(collection.name)
    defer delete(collectionPath)
    os.remove(collectionPath)
}
