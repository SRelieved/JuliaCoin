
include("Block.jl")
include("Transaction.jl")
include("miner.jl")

using HTTP, Random, Bukdu, UUIDs, Dates, JSON, Sockets

#Initiate a blockchain, create a coinbase transaction, a first block and delete the coinbase transaction from mempool
juliablockchain = Blockchain()

coinbasegenesistransaction('aa52a1d909a4515ac04be4dedf92d597b0e6e865', juliablockchain, amount = 25000)

firstdifficulty = "000000"

create_block(juliablockchain, 0, "0", firstdifficulty)


#Create ip address, name, port and url for request
hostip = getipaddr()
hostname = getnameinfo(hostip)
hostip = string(hostip)
jcoinport = input("Enter the port number for running the app: ")
jcoinport = parse(Int64, jcoinport)
urlrequest = "http://"*hostip*":"*string(jcoinport)

#Creating a Web App (interact with the blockchain with get request)
struct CryptoController <: ApplicationController
    conn::Conn
end



#Test if the key exist within a dictionnary and if all keys are present
function keyexist(data, cle)
   try
      data[cle]
      return true
   catch thiserror
      if isa(thiserror, KeyError)
         return false
      end
   end
end

function allkeysin(data, keylist)
   for i in keylist
      if i in keys(data)
         continue
      else
         return false
      end
   end 
   return true
end    

#Adding a new transaction to the Blockchain 
function addtransaction(c::CryptoController)
   req = c.conn.request
   data = Dict(req.headers)
   transaction_keys =["source", "destination", "private_key", "tx_type"]
   txhashexist = keyexist(data, "tx_hash")
   if txhashexist == false 
      keysok = allkeysin(data, transaction_keys)  
      if keysok == false
         return "Some elements of the transaction are missing", 400
      else
         newassetexist = keyexist(data, "asset")
         if newassetexist == false 
            newasset = ""
         else
            newasset = data["asset"]
         end
         newcodeexist = keyexist(data, "code")
         if newcodeexist == false
            newcode = ""
         else
            newcode = data["code"]
         end
         if data["tx_type"] == "7"
            amount, fee = 0, 0
         else
            amount, fee = data["amount"], data["fee"]                
         end  
         new_transaction = Transaction.create_transaction(pythonblockchain, source = data["source"], destination = data["destination"], private_key = data["private_key"], amount = amount, fee = fee, tx_type = data["tx_type"], prev_hash = "0", asset = newasset, code = newcode)
         if juliablockchain.nodes != []
            Transaction.broadcast_transaction(juliablockchain, new_transaction)
         end
         answer =  Dict("message": "This transaction will be added to the mempool and broadcasted to others nodes!")
         return json(answer), 201
   else     
      tx_list = [transac["tx_hash"] for transac in juliablockchain.mempool]
      if (data["tx_hash"] in tx_list) == false
         new_transaction = Dict("source"=> data["source"],
                                "destination"=> data["destination"],
                                "amount"=> data["amount"],
                                "fee"=> data["fee"],
                                "tx_type"=> data["tx_type"],
                                "code"=> data["code"],
                                "timestamp"=> data["timestamp"],
                                "signature"=> data["signature"],
                                "tx_hash"=> data["tx_hash"],
                                "asset"=> data["asset"],
                                "prev_hash"=> data["prev_hash"])
         Transaction.addtomempool(new_transaction, juliablockchain)
         Transaction.broadcast_transaction(juliablockchain, new_transaction)
         answer = {"message": "This transaction will be added to the next block"}
         return json(answer), 201        
      else
         answer = {"message": "This transaction is already in the mempool, we will ignore it! "}
         return json(answer), 201        
      end
   end       
end


routes() do
    post("/addtransaction", CryptoController, addtransaction)
end

#Mining a new block

function mineblock(c::CryptoController)
   req = c.conn.request
   data = Dict(req.headers)        
   actualminer = miner(data["server"], data["public_key"])
   previous_block = juliablockchain.get_previous_block()
   previous_proof = previous_block["blockheader"]["nonce"]
   previous_hash = previous_block["current_hash"]
   if ((previous_block["height"] + 1) % 2016) == 0
      difficulty = juliablockchain.modify_difficulty(previous_block["height"] + 1)
   else
      difficulty = previous_block["difficulty"]
   end
   proof = Blockchain.proof_of_work(previous_proof, difficulty)
   payminer(actualminer, 25)
   block = create_block(juliablockchain, proof, previous_hash, difficulty)
   paycoders(50, block, juliablockchain)
   delete_transactions_from_mempool(block, juliablockchain)
   juliablockchain.sendnewblock(block, data["server"]) 
   answer = Dict("message"=> "congratulations, you just mined a block!",
                 "index"=> block["height"],
                 "timestamp"=> block["blockheader"]["timestamp"],
                 "proof"=> block["blockheader"]["nonce"],
                 "previous_hash"=> block["blockheader"]["previous_hash"],
                 "transactions"=> block["transactions"])
   return json(answer)
end

routes() do
    get("/mine_block", CryptoController, mineblock)
end


#Getting the full Blockchain

function get_chain(c::CryptoController)
   answer = Dict("chain"=> juliablockchain.chain,
                 "length"=> length(juliablockchain.chain),
                 "mempool"=> juliablockchain.mempool,
                 "nodes"=> juliablockchain.nodes)
   return json(answer)
end

routes() do
    get("/get_chain", CryptoController, get_chain)
end

#checking if the Blockchain is valid

function is_valid(c::CryptoController)
   is_valid = is_chain_valid(juliablockchain.chain)
   if is_valid
      answer = Dict("message"=> "All good. The Blockchain is valid.")
   else
      answer = Dict("message"=> "Houston, we have a problem. The Blockchain is not valid.")
   end
   return json(answer)
end

routes() do
    get("/is_valid", CryptoController, is_valid)
end

#Connecting new nodes

function connect_node(c::CryptoController)
   pathofnodes = loadjson()
   open(pathofnodes, "r") do f
      global nodesdict 
      dicttxt = read(f)
      dictio = String(dicttxt)
      nodesdict =JSON.parse(dictio)      
   end 
   if nodesdict["nodes"] == nothing
      return "No node", 401
   end
   for node in nodesdict["nodes"]
      if node != urlrequest
         juliablockchain.add_node(node)
      else
         continue
      end
   end
   answer = Dict("message"=> "All the nodes are now connected, the juliablockchain now contains the following nodes: ", "total_nodes"=> juliablockchain.nodes)
   return json(answer), 201
end


routes() do
    post("/connect_node", CryptoController, connect_node)
end

#Replacing the chain by the longest chain if needed

function replace_chain(c::CryptoController)
   global juliablockchain
   is_chain_replaced = juliablockchain.replace_chain()
   if is_chain_replaced[0] == true
      answer = Dict("message"=> "The nodes have different chain so the chain was replaced by the longest one", "new_chain"=> juliablockchain.chain)
   else
      answer = Dict("message"=> "All good, the chain is the largest one", "actual_chain"=> juliablockchain.chain)
   end
   return json(answer), 200
end


routes() do
    get("/replace_chain", CryptoController, replace_chain)
end




#Two functions have to be reviewed

function requestnodelist(c::CryptoController)
   newnodes = juliablockchain.requestnodelist()
   for i in newnodes
      if i != urlrequest
         juliablockchain.add_node(i)
      end
   end
   response = dict("message" : "All new nodes have been added", "nodes": newnodes)
   return json(response), 200
end

routes() do
    get("/requestnodelist", CryptoController, requestnodelist)
end



function receive_block(c::CryptoController)
   req = c.conn.request
   yourdata = Dict(req.headers)  
   data = yourdata["new_block"]
   server = yourdata["server"]
   if server not in juliablockchain.nodes
      push!(juliablockchain.nodes, server)
   end
   block_keys = ["height", "transactions", "blockheader", "current_hash", "difficulty"]
   keysok = allkeysin(data, block_keys) 
   if keysok == false
      return("Some elements of the block are missing"), 400
   else
      if data["blockheader"]["previous_hash"] == juliablockchain.chain[end]["current_hash"]
         for j in data["transactions"]
            if j["tx_type"] != "0"
               if verify_transaction(j, juliablockchain) == False
                  return("At least one transaction is not valid in that block"), 400
               else
                  continue
               end
            end
         end
         if calculate_merkle_root(data["transactions"]) == data["blockheader"]["merkle_root"]
            create_block(juliablockchain, data["blockheader"]["nonce"], data["blockheader"]["previous_hash"], data["difficulty"])
         else
            return("Merkle root doesn't match"), 400
         end
      else
         return("Previous hash doesn't fit with current hash of previous block"), 400
      end
   end
end


routes() do
    post("/receive_block", CryptoController, receive_block)
end



function loadjson()
   thedirectory = Pkg.dir("JuliaCoin")
   newdirectory = thedirectory * "json\\nodes.json"
   return newdirectory
end




#Creating url for request

connectnode = urlrequest*"/"*"connect_node"
miningblock = urlrequest*"/"*"mine_block"
replacechain = urlrequest*"/"*"replace_chain"
getchain = urlrequest*"/"*"get_chain"



#running the app

Bukdu.start(jcoinport, host = hostip)






