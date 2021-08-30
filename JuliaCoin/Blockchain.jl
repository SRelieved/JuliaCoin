using JSON, SHA, Dates, Statistics


export blockchain, Blockchain

abstract type blockchain end


mutable struct Blockchain <: blockchain
   #=
   
     A structure used to represent a Blockchain
   
     Parameters
     ----------
     chain : list, optional, default []
         a list that contains multiple blocks of data
     mempool : list, optional, default []
         a list that contains multiple transactions ready to be added to the next block of the blockchain
     nodes : list, optional, default None
         a list that contains all the nodes server url in order to get their own version of the blockchain and broadcast
         transactions from this mempool
      
     Attributes
     ----------
     chain : list
         a list that contains multiple blocks of data
     mempool : list
         a list that contains multiple transactions ready to be added to the next block of the blockchain
     nodes : list
         a list that contains all the nodes server url in order to get their own version of the blockchain and broadcast
         transactions from this mempool
   
     Methods
     -------
     get_previous_block(self)
         return the information from the latest block added to the blockchain
     get_previous_block(self, node)
         add a node to the nodes list if the node returns a 200 answer when interrogates
     replace_chain(self)
         return True or False wether or not the chain should be replaced by a longer chain coming from another node
     requestnodelist(self)
         return a nodes list from already known nodes. Those nodes have to respond and not to be in our actual nodes list.
     modify_difficulty(self, height)
         return adjusted difficulty
   =#
   chain::Array
   mempool::Array
   nodes::Array
   Blockchain(chain=[], mempool=[],nodes=nothing) = begin
      chain = []
      mempool = []
      nodes = []
   new(chain, mempool,nodes)
   end
end


function get_previous_block(Blockchain::Blockchain)
   #return the last blockchain of the chain
   return Blockchain.chain[end]
end


function proof_of_work(previous_proof, difficulty)
   #=
      Calculate new proof of work
   
         Return a valid proof of work for a certain difficulty
   
         Parameters
         ----------
         previous_proof : Int
             The valid proof of work of the previous block in the chain.
         difficulty : String
             The number of zero with which the hash signature has to start with to be valid. 
   
         Returns
         -------
         out : Proof of Work
             An Int number that constitutes the valid proof of work for the new block. 
         Examples
         --------
         >>>proof_of_work(122,"0000")
         
   =#
   new_proof = 1
   check_proof = false
   while check_proof == false
      hash_operation = bytes2hex(sha256(json(new_proof^2 - previous_proof^2)))      
      if hash_operation[1:length(difficulty)] == difficulty
         check_proof = true
      else
         new_proof += 1
      end
   end
   return new_proof
end


function is_chain_valid(Chain::Array)
   #=
      Verify if the chain of the blockchain is valid
         Return True or False
   
         Parameters
         ----------
         chain : List
             List of blocks already created
   
         Returns
         -------
         out : Boolean value
             Return True if the chain is valid and False if the chain is not valid.
         Notes
         -----
         It verify if:
            - The hash of the previous block is valid by calculating again the hash signature of the blockheader of the previous block.
            - Verify if the proof is valid based on the difficulty level.
         Examples
         --------
         >>>is_chain_valid(chain)
   =#
   chain = Chain
   previous_block = chain[1]
   block_index = 2
   while block_index < length(chain)
      block = chain[block_index]
      if block["blockheader"]["previous_hash"] != calculate_block_hash(previous_block["blockheader"])
         return false
      end
      previous_proof = previous_block["blockheader"]["nonce"]
      proof = block["blockheader"]["nonce"]
      hash_operation = bytes2hex(sha256(json(proof^2 - previous_proof^2)))  
      if hash_operation[1:length(block["difficulty"])] != block["difficulty"]
         return false
      end
      previous_block = block
      block_index += 1
   end
   return true
end



function trynode(node::String)
   # Try to connect to a certain node and verify if the response status is equal to 200. Return either True or False.
   try HTTP.request("GET", node)
      return true
   catch node
      return false
   end
end


function add_node(Blockchain::Blockchain, node::String)
   #=
   
      Adding a node to a blockchain
   
         Append a new node to the existing nodes list of a blockchain if node is reachable
   
         Parameters
         ----------
         node : string,
             a string representing the node's url
         server : string, optional
             a string representing our server's url
             default is None
   
         Returns
         -------
         out : Append the string url to the actual blockchain's nodes list
             Node's url is now appended to the blockchain's nodes list. 
         Examples
         --------
         >>>Blockchain.add_node("127.0.0.1:5000")           
   =#
   if node not in Blockchain.nodes
      url = node*"/get_chain"
      available = trynode(url)
      if available == true
         push!(Blockchain.nodes, node)
      else
         print("Impossible to join the node") 
      end  
   end
end


function replace_chain(juliablockchain::Blockchain)
   #=
      Replacing the blockchain's chain
         Determine if the actual chain has to be replaced by a longer chain from another node.
   
         Parameters
         ----------
         None
   
         Returns
         -------
         out : Return True if it has to be replaced and false if it doesn't. 
             If True is returned, the longest chain then replace the actual chain.
         Examples
         --------
         >>>Blockchain.replace_chain()       
   =#
   network = juliablockchain.nodes
   longest_chain = nothing
   max_length = length(juliablockchain.chain)
   if network != []
      for node in network
         url = node*"/get_chain"
         responses = HTTP.request("GET", string(url))  
         if responses.status == 200
            responsestring = String(responses.body)
            responsestring = JSON.parse(responsestring)
            len = responsestring["length"]
            newchain = responsestring["chain"]
            global newchain, len
            if len > max_length && is_chain_valid(newchain)
               max_length = len
               longest_chain = newchain
            end
         end
      end
      if longest_chain != nothing
         juliablockchain.chain = longest_chain
         return true
      else
         return false
      end
   else
      return false
   end
end



function modify_difficulty(height, blockchain::Blockchain)
   #=
      Modify difficulty of blockchain
         Return the adjusted difficulty of the blockchain
   
         Parameters
         ----------
         height : Int
             The actual size of the blockchain in term of number of blocks.
   
         Returns
         -------
         out : Adjusted difficulty
             The adjusted difficulty to be used for the mining process. The difficulty is the number of zero with which the hash
             signature of the next block has to start with. For example a mining difficulty of "0000" means that a valid hash
             signature for the next block would look as follow: "000016bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad". 
         Examples
         --------
         >>>Blockchain.modify_difficulty(144)
   =#
   listofblocks = blockchain.chain[height-11:height-1]
   totaltime = []
   i = 2
   while i < length(listofblocks)
      timebetblocks = DateTime(listofblocks[i].timestamp) - DateTime(listofblocks[i-1].timestamp)
      difference = timebetblocks/1000
      push!(totaltime, difference)
      i += 1
   end
   averagetime = mean(totaltime)
   if averagetime < 600
      newdifficulty = blockchain.chain[height-1]["difficulty"]*"0"
   else difference > 600
      len = length(blockchain.chain[height-1]["difficulty"])
      newdifficulty = blockchain.chain[height-1]["difficulty"][1:len-1]
   end
   return newdifficulty
end


function requestnodelist(Blockchain::Blockchain)
   #request the nodes list from others nodes: Append that nodes list to the actual node's nodes list
   network = Blockchain.nodes
   newnodes = []
   if network != []
      for node in network
         if node not in network
            URL = node + "/get_chain"
            available = trynode(URL)
            if available == true
               responses = HTTP.request("GET", URL)
               nodelist = JSON.parse(responses)["nodes"]
               for i in nodelist
                  if i not in network
                     push!(newnodes, i)
                  end
               end
            end
         end
      end
   end
   return newnodes
end

function sendnewblock(Blockchain::Blockchain, newblock::Dict, server::String)
   #=
      Send the new mined block to others nodes
      Broadcast a new block to a connected node in order for the node to add it to its existing blocks list
   
      Parameters
      ----------
      newblock : dictionary,
          #a dictionary representing a new confirmed block of data to be added to the blockchain
   
      Returns
      -------
      out : 
          Node receives the blocks and verify it before appending it to its actual blockchain 
      Examples
      --------
      >>>Blockchain.sendnewblock(newblock)  
   =#
   network = Blockchain.nodes  
   for node in network
      try
         URL = node + "/receive_block"
         arguments = Dict("new_block" => newblock, "server" => server)
         HTTP.request("POST", URL, arguments)
      end
   end
end
