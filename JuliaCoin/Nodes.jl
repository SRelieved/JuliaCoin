using Random
using UUIDs
using URIParser


addresse = "http://127.0.0.1:5000"
address1 = "http://127.0.0.1:5001"
address2 = "http://127.0.0.1:5002"
address3 = "http://127.0.0.1:5003"
liste = [addresse, address1, address2, address3]

function create_address()
   rng = MersenneTwister(1234)
   node_address = uuid1(rng)
   node_address = replace(string(node_address), "-" => "")
   return node_address
end




function connect_node(c::CryptoController)
    global liste, juliablockchain
    if liste == nothing
        return "No node", 400
    end
    for node in liste
        push!(juliablockchain.nodes, node)
    end
    response = Dict("message" => "All the nodes are now connected. The Hadcoin Blockchain now contains the following nodes:",
                "total_nodes" => juliablockchain.nodes)
    return json(response), 201 
end

routes() do
    get("/connect_node", CryptoController, connect_node)
end






#Other possibility: Use the JSON.parse for parsing the URL before pushing it within the nodes set

