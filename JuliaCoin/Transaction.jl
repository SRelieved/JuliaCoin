
using JSON,Dates,SHA


include("Wallet.jl")
include("codes_writing.jl")


tx_types = Dict("0" => "coinbase/genesis",
                "1" => "standard",
                "2" => "asset creation",
                "3" => "asset addendum",
                "4" => "order",
                "5" => "fill",
                "6" => "registration",
                "7" => "Codes Development")



#Create transaction function using input from user

function create_transaction(juliablockchain::Blockchain, source = nothing, destination = nothing, private_key = nothing, amount::Union{Int64, Float64} = 0, fee::Union{Int64, Float64} = 0, tx_type = nothing, prev_hash::String = "0", asset = nothing)
   #=
     Create a transaction to be added to the mempool attributes of a blockchain object
    
         Return a dictionnary as a transaction that is also appended to the mempool attributes of a blockchain object
         
         Parameters
         ----------
         juliablockchain : Blockchain
             An object of type blockchain 
         source : address
             An address from which the cryptocurrency will be taken, given under the form of a string
         timestamp = String, optional, default None
             The timestamp representing when the block has been created
         destination : coincurve.keys.PublicKey, optional, default None
             A public key or an address to receive the cryptocurrency, given under the form of a string
         private_key : coincurve.keys.PrivateKey, optional, default None
             A private_key used to sign the transaction in order to prove that the cryptocurrencies belong to the initiater of 
             the transaction
         amount : Float, optional, default 0.00
             The amount of cryptocurrency to be transacted in the transaction
         fee : Float, optional, default 0.00
             The amount of fee to be paid to miners for the transactions
         tx_type : string, optional, default None
             A string representing a type of transaction (can be 1,2,3,4,5,6 or 7)
         prev_hash : String, optional, default "0"
             The hash signature of the previous block 
         asset : String, optional, default None
             A string element representing an asset to be transfered
         code : String, optional, default None
             A python code that is being submitted on the blockchain for getting a reward
             
         Returns
         -------
         out : Dictionnary object
             A dictionnary object will be appended to the mempool list of a blockchain object. 
         Examples
         --------
         >>>create_transaction(juliablockchain, XXX, '2019-08-18 11:30:31.274561', XXX, XXX, 22.0, 1.75, "1", "0")
   =#
   if source == nothing
      source = input("Please enter source's public key? ")
   else
      source = source
   end
   if destination == nothing
      destination = input("Please enter destination's public key? ")
   else
      destination = destination
   end
   if private_key == nothing
      private_key = input("Enter the private key: ")
   else
      private_key = private_key
   end
   if amount == 0
      inputamount = input("How much JuliaCoin would you like to send ? ")
      amount = parse(Float64,inputamount)
   else
      amount = Float64(amount)
   end
   if fee == 0
      inputfee = input("How many fees are you willing to pay? ")
      fee = parse(Float64,inputfee)
   else
      fee = Float64(fee)
   end
   if tx_type == nothing
      tx_type = input("What type of transaction is it? ")
      while tx_type ∉ keys(tx_types) || tx_type == "0"
         tx_type = input("Wrong tx_type please select a good one: ")
      end
   end
   if tx_type == "7"
      code = write_codes()
   else
      code = ""
   end
   timestamp = now() 
   if asset == nothing
      asset = "29bb7eb4fa78fc709e1b8b88362b7f8cb61d9379667ad4aedc8ec9f664e16680"
   else
      asset = asset
   end
   data = Dict(
         "source"=> source,
         "destination"=> destination,
         "amount"=> amount,
         "fee"=> fee,
         "timestamp"=> timestamp,
         "asset"=> asset,
         "prev_hash"=> prev_hash)
   signature = sign(data, private_key)
   tx_hash = calculate_tx_hash(data, signature)
   new_transaction = Dict("source" => source,
                          "destination" => destination,
                          "amount" => amount,
                          "fee" => fee,
                          "tx_type" => tx_type,
                          "code" => code,
                          "timestamp" => timestamp,
                          "signature" => signature,
                          "tx_hash" => tx_hash,
                          "asset" => string(asset),
                          "prev_hash" => prev_hash) 
   addtomempool(new_transaction, juliablockchain)
end




function calculate_tx_hash(data::Dict, signature)
   #calculate the sha256 signature for a transactions data. Data should be a dictionary representing a transaction
   data1 = data
   push!(data1, "signature" => signature)
   hash = bytes2hex(sha256(json(data)))      
   return hash
end


function signer(data::Dict, private_key::Array)
   #sign data with private key
   signature1 = signature(data,private_key)   
   return signature1
end





function verify_transaction(new_transaction::Dict, juliablockchain::Blockchain)
     #= 
      Verify if transaction is valid
    
         Verify if the signature is valid according to public_key and if the source has enough cryptocurrency on the blockchain
         
         Parameters
         ----------
         new_transaction : dictionary
             A dictionary representing a transaction
         juliablockchain : Blockchain
             An object of type blockchain
             
         Returns
         -------
         out : boolean
             return Boolean; True if transaction is valid and False if invalid

         Examples
         --------
         >>>verify_transaction(new_transaction, juliablockchain)

   =#
   data = Dict(
         "source"=> new_transaction["source"],
         "destination"=> new_transaction["destination"],
         "amount"=> new_transaction["amount"],
         "fee"=> new_transaction["fee"],
         "timestamp"=> new_transaction["timestamp"],
         "asset"=> new_transaction["asset"],
         "prev_hash"=> new_transaction["prev_hash"])
   goodtransaction = verify(data, new_transaction["signature"], new_transaction["source"])
   if goodtransaction == false
      return false
   else
      if length(juliablockchain.chain) == 0
         return false
      else
         balance = calculate_balance(new_transaction["source"], juliablockchain)
         if balance >= new_transaction["amount"] + new_transaction["fee"]
            return true
         else
            return false
         end
      end
   end
end



#Add transaction to mempool
function addtomempool(new_transaction::Dict, juliablockchain::Blockchain)
   #Verify if transaction is valid and append it to the blockchain mempool. Take a dictionary representing the new transaction and the juliablockchain as arguments
   if verify_transaction(new_transaction, juliablockchain) == true
      push!(juliablockchain.mempool, new_transaction)
      new_transaction = nothing
   else
      new_transaction = nothing
      print("Transaction is not valid, cannot add it to the mempool!")
   end
end




#Sort transaction in the mempool
function sortfee(mempool::Array)
   #function to sort the transactions within the mempool based on fees amount and tx_type. Returns the new sorted mempool with tx_type "7" and highest fees first
   codingmempool = filter(x->x["tx_type"] == "7", mempool)
   codingmempool = sort(collect(codingmempool), by=x->x["fee"])
   newmempool = filter(x->x["tx_type"] != "7", mempool)
   newmempool = sort(collect(newmempool), by=x->x["fee"])
   mempool = codingmempool + newmempool
   return mempool
end


function select_transactions(juliablockchain::Blockchain, numberoftransactions::Int64=nothing)
    #=
      Select a number of transactions for the next block to be mined.
    
         It first interrogates all the nodes connected to it to receive the transactions within their mempool, 
         then verify all transactions added, sort it based on fees amount and transaction type and finally returns the list of 
         transactions to be added to the next block
         
         Parameters
         ----------
         juliablockchain : Blockchain
             An object of type blockchain
         source : integer
             The number of transactions to be added to the next block.
             
         Returns
         -------
         out : list object
             A list object containing dictionaries that represent valid and verified transactions ready to be added to the new 
             block.

         Examples
         --------
         >>>select_transactions(juliablockchain, 100)

   =#
   if numberoftransactions != nothing
      if numberoftransactions <= length(juliablockchain.mempool)
         numberoftransactions = numberoftransactions
      else 
         numberoftransactions = length(juliablockchain.mempool)
      end
   else
      print("Error: number of transactions required, ")
      numberoftransactions = input("How many transactions do you want to add to the next block? ")
      numberoftransactions = parse(Int64,len)
   end
   mempool = sortfee(juliablockchain.mempool)
   blocktransactions = mempool[1:numberoftransactions]
   if length(juliablockchain.mempool) > numberoftransactions
      juliablockchain.mempool = mempool[numberoftransactions+1:end]
   else
      juliablockchain.mempool = []
   end
   return blocktransactions
end


function coinbasegenesistransaction(destination, juliablockchain, amount=nothing)
   source = [0000]
   destination = destination
   amount = 10000
   fee = 0
   tx_type = "0"
   code = "Using juliablockchain"
   timestamp = now() 
   signature = "0000"
   asset = "0000"
   prev_hash = "0"
   data = Dict(
         "source"=> source,
         "destination"=> destination,
         "amount"=> amount,
         "fee"=> fee,
         "timestamp"=> timestamp,
         "asset"=> asset,
         "prev_hash"=> prev_hash)
   tx_hash = calculate_tx_hash(data, signature)
   new_transaction = Dict("source" => source,
                          "destination" => destination,
                          "amount" => amount,
                          "fee" => fee,
                          "tx_type" => tx_type,
                          "code" => code,
                          "timestamp" => timestamp,
                          "signature" => signature,
                          "tx_hash" => tx_hash,
                          "asset" => string(asset),
                          "prev_hash" => prev_hash)    
   push!(juliablockchain.mempool, new_transaction)
   new_transaction = nothing
end   


function broadcast_transaction(Blockchain::Blockchain, newtransaction::Dict)
   #Broadcast a new transaction to the connected nodes by using a post requests with the addtransaction function. 
   if verify_transaction(new_transaction, Blockchain) == true
      for i in Blockchain.nodes
         URL =  i+"/addtransaction"
         arguments = Dict("source"=> newtransaction["source"], "destination"=> newtransaction["destination"],
                          "amount"=> newtransaction["amount"], "fee"=> newtransaction["fee"], "tx_type"=> newtransaction["tx_type"],
                          "prev_hash"=> newtransaction["prev_hash"], "asset"=> newtransaction["asset"], "code"=> newtransaction["code"],
                          "tx_hash"=> newtransaction["tx_hash"], "timestamp"=> newtransaction["timestamp"],
                          "signature"=> newtransaction["signature"])
         HTTP.request("POST", URL, arguments)
      end
   end
end


function delete_transactions_from_mempool(block::Dict, Blockchain::Blockchain)
   #Function to delete transactions within the mempool that already exist within the blockchain
   for i in Blockchain.mempool
      if transactionexist(block["transactions"], i) == true
         filter!(x->x≠i,Blockchain.mempool)
      end
   end
end
