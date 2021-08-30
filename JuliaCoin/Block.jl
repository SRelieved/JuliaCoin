using SHA, JSON, YAML, Logging, Dates

include("Blockchain.jl")



function createblockheader(previous_hash::String, merkle_root::String, nonce::Int64 = 0, timestamp::String = "")
      #=
      
         Create the block header for the next block with the hash of the previous block, the merkle root, the nonce and the timestamp
    
         Return a dictionnary as a block of data that is also appended to the chain attributes of a blockchain object
   
         Parameters
         ----------
         previous_hash : String
             A string element that represents the sha256 hash signature of the previous block in the chain
         proof : String
             A string element that represents the merkle root signature of the transactions
         nonce: Int, optional, default 0
             The proof of work that allowed us to mine a new block
         timestamp = String, optional, default None
             The timestamp representing when the block has been created
             
         Returns
         -------
         out : Dictionnary object
             A dictionnary object that will act as the Block Header for the next block. 
             
         Examples
         --------
         >>>createblockheader("0", "baa2b5a285d52b3933e1554e0cb9a0a6216bd93a3f19d03ab6ee40907a68f646", 165256, '2019-08-18 11:30:31.274561')
         
   =#  
   if timestamp != ""
      timestamp = timestamp
   else
      timestamp = string(now())
   end
   newblockheader = Dict("previous_hash" => previous_hash,
                         "merkle_root" => merkle_root,
                         "nonce" => nonce,
                         "timestamp" => timestamp)
   return(newblockheader)
end


function create_block(juliablockchain::Blockchain, proof::Int64, previous_hash::String, difficulty::String, transactions::Array = nothing, timestamp::String = nothing) 
   #=
         Create a block of data to be added to the chain attributes of a blockchain object
    
         Return a dictionnary as a block of data that can be appended to the chain attributes of a blockchain object
      
         Parameters
         ----------
         juliablockchain : Blockchain
             An object of type blockchain 
         proof : Int
             A valid proof of work for the block
         previous_hash : String
             The hash signature of the previous block 
         difficulty: String
             The number of zero by which the hash signature has to begin in order to be valid.
         transactions: list, optional, default None
             The list of transactions to be added to the block
         timestamp = String, optional, default None
             The timestamp representing when the block has been created
      
         Returns
         -------
         out : Dictionnary object
             A dictionnary object will be appended to the chain list of a blockchain object.
         Examples
         --------
         >>>create_block(juliablockchain, 168468, "000", "0000")
   =#
   height = length(juliablockchain.chain) + 1
   if transactions == nothing
      transactions = select_transactions(juliablockchain, 100)
   else
      transactions = transactions
   end
   if timestamp == nothing
      timestamp = string(now())
   else
      timestamp = timestamp
   end
   merkle_root = calculate_merkle_root(transactions)
   blockheader = createblockheader(previous_hash, merkle_root, proof, timestamp)
   current_hash = calculate_block_hash(blockheader)
   difficulty = difficulty
   newblock = Dict("height" => height,
                    "transactions" => transactions,
                    "blockheader" => blockheader,
                    "current_hash" => current_hash,
                    "difficulty" => difficulty)
   push!(juliablockchain.chain, newblock)
   return(newblock)
end


function to_hashable(blockheader::Dict)
   #Transform the blockheader dictionary as a hashable string
   return string(blockheader["previous_hash"]*blockheader["merkle_root"]*blockheader["timestamp"]*string(blockheader["nonce"]))
end


function hash_difficulty()
   difficulty=0
   for c in current_hash
      if c != "0"
         break
      end
      difficulty +=1
      return difficulty
   end
end
      



function transactions_queue(juliablockchain::Blockchain)
   if length(juliablockchain.mempool) <= 1
      return juliablockchain.mempool
   end
   coinbase = juliablockchain.mempool[0]
   sorted_transactions = sort(juliablockchain.mempool[1:end], key=lambda, x: x.tx_hash)
   unshift!(sorted_transactions, coinbase)
   return sorted_transactions
end




function calculate_block_hash(blockheader::Dict)
   #First make the blockheader hashable through the to_hashable function and then use the bytes2hex function to create a hash signature based on the blockheader information
   header = to_hashable(blockheader)
   return bytes2hex(sha256(header))
end



function calculate_merkle_root(transactions::Array)
   #Calculate the merkle root of a list of transactions. Parameter is an array of transactions. It returns the merkle base. 
   if length(transactions) < 1
      error("Zero transactions in block. Coinbase transaction required")
   end
   merkle_base = []
   for t in transactions
      push!(merkle_base, t["tx_hash"])
   end
   while length(merkle_base) > 1
      temp_merkle_base = []
      for i in collect(1:2:length(merkle_base))
         if i == length(merkle_base) - 1
            push!(temp_merkle_base, bytes2hex(sha256(merkle_base[i])))
         else
            push!(temp_merkle_base, bytes2hex(sha256(merkle_base[i]*merkle_base[i+1]))) 
         end       
      end
      merkle_base = temp_merkle_base
   end
   return merkle_base[1]
end


function block_verification_process(blockchain, block, previous_hash, current_hash, height, previous_block = nothing, difficulty = nothing)
   #=
         Verification process for a block to be added to the blockchain
    
         Return a boolean value of True or False depending on the validity of the block
         
         Parameters
         ----------
         juliablockchain : Blockchain
             An object of type blockchain 
         block : Dictionnary
             A dictionnary object that represents a block of transactions to be verified before being added on the blockchain
         previous_hash : String
             The hash signature of the previous block 
         current_hash : String
             The hash signature of the dictionnary object that represents a block of transactions to be verified before being added on the blockchain
         height: Integer
             An Integer that represents the block position within the blockchain
         previous_block L Dictionnary
             A dictionnary object that represents the last block of transactions on the blockchain
         difficulty: String
             The number of zero by which the hash signature has to begin in order to be valid.
         
         Returns
         -------
         out : Boolean value
             A boolean value of True or False that indicate if the new block to be added on the blockchain is valid
         Examples
         --------
         >>>block_verification_process(juliablockchain, newblock, "000", "000", 33)
   =#  
   if previous_block != nothing
      if previous_hash != previous_block["current_hash"]
         return false
      else
         the_hash = calculate_block_hash(block["blockheader"])
         if the_hash != current_hash
            return false
         else
            if calculate_merkle_root(block["transactions"]) != block["blockheader"]["merkle_root"]
               return false
            else
               for j in block["transactions"]
                  if j["tx_type"] != "0"
                     if verify_transaction(j, blockchain) == false
                        return false
                     end
                  end
               end
               if difficulty != nothing
                  if the_hash[1:length(difficulty)] == difficulty
                     return true
                  end
               else
                  return true
               end
            end
         end
      end
   else
      the_hash = calculate_block_hash(block["blockheader"])
      if the_hash != current_hash
         return false
      else
         if calculate_merkle_root(block["transactions"]) != block["blockheader"]["merkle_root"]
            return false
         else
            for j in block["transactions"]
               if j["tx_type"] != "0"
                  if verify_transaction(j, blockchain) == false
                     return false
                  end
               end
            end
            return true
         end
      end               
   end
end
                                             

function verify_block(juliablockchain::Blockchain, block::Dictionary)
   #=
         Function that prepares and feeds the information for the block_verification_process function and calls it subsequently
    
         Return a boolean value of True or False depending on the validity of the block
         
         Parameters
         ----------
         juliablockchain : Blockchain
             An object of type blockchain 
         block : Dictionnary
             A dictionnary object that represents a block of transactions to be verified before being added on the blockchain
         
         Returns
         -------
         out : Boolean value
             A boolean value of True or False that indicate if the new block to be added on the blockchain is valid
         Examples
         --------
         >>>verify_block(juliablockchain, newblock)
   =#  
   previous_hash = block["blockheader"]["previous_hash"]
   current_hash = block["current_hash"]
   height = block["height"]
   if height > 1 and length(juliablockchain.chain) > 1
      previous_block = juliablockchain.chain[height-2]
      if height%2016 == 0
         difficulty = modify_difficulty(height, juliablockchain)
      else
         difficulty = previous_block["difficulty"]
      end
   elseif height == 1 and length(juliablockchain.chain) == 1
      previous_block = nothing
      difficulty = nothing
   elseif height == 2 and length(juliablockchain.chain) == 1
      previous_block = juliablockchain.chain[1]
      difficulty = nothing   
   else
      previous_block = nothing
      difficulty = nothing
   end
   verif = block_verification_process(juliablockchain, block, previous_hash, current_hash, height, previous_block = None, difficulty = None)
   return verif
end
