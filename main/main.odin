package main

import "core:fmt"
import lib"../src/library"
import "../src/core/server"

main ::proc (){
    using lib
    using server

    newServer:= new(Server)
    result:= start_ostrich_server(newServer)
    fmt.println("Server Result: ",result)

}