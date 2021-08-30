
include("RSA.jl")
include("Blockchain.jl")
include("ripemd.jl")
using StatsBase, SHA, JSON


#Input function for user to input data while creating transaction
function input(prompt::String="")::String
   print(prompt)
   return chomp(readline())
end

struct address
   #=
    A class used to represent an address for receiving cryptocurrency. This class allows a user to create an address that will store his public key and derive an address
     
      Parameters
     ----------
     public_key : coincurve.keys.PublicKey
         The public key derived from the private_key
     
      Attributes
     ----------
     address : string
         the address derived from the public key
     Example:
         address(public_key)
    
   =#  
   address::String
   address(public_key) = begin   
      addresse = ripemd160(string(sha256(string(public_key))))
      addresse1 = "0x00"*addresse
      new(addresse1)
   end
end

struct client <: blockchain
   #=
      
    Create an object of class client: This class allows a user to create an object of class client with private key, public key and address
   
     Parameters
     ----------
     secret1 : bytes, optional, default None
         The secret from which the private key can be derived
      
     Attributes
     ----------
     private_key : coincurve.keys.PrivateKey
         the private_key from which public_key will be derived
     public_key : coincurve.keys.PublicKey
         The public key derived from the private_key
     address : string
         the address derived from the public key
         
     Example:
         client()
         client(secret)  
         
   =#
   private_key::Array
   public_key::Array
   addresse::address
   client(private_key = nothing, public_key = nothing, addresse = nothing) = begin
      if private_key == nothing
         key = RSA1024()
         private_key = PrivRSA1024(key)
         public_key = PublicRSA1024(key)
         private_key = json(private_key)
         public_key = json(public_key)
         private_key = JSON.parse(private_key, inttype=BigInt)["privateKey"]
         public_key = JSON.parse(public_key, inttype=BigInt)["publicKey"] 
         addresse = address(public_key)
      else
         private_key = private_key
         public_key = public_key
         addresse = addresse
      end
      new(private_key, public_key, addresse)
   end
end




function sign(message::Dict{String,Any}, privRSA::Array{Any,1})
    #function to sign a message based on a private RSA key
    m = calcm(Array{UInt8}(string(message)), BigInt(length(string(message))))
    h = hash(m)
    s = h % privRSA[1]
    return powermod(s,privRSA[2],privRSA[1])
end

function verify(message::Dict{String,Any}, signa::BigInt, publicRSA::Array{Any,1})
    #Verify if the signature is valid given the message, the public_key and the signature, return a boolean True or False
    m = calcm(Array{UInt8}(string(message)), BigInt(length(string(message))))
    w = powermod(signa, publicRSA[2], publicRSA[1])
    v = hash(m) % publicRSA[1]
    return v == w
end


function calculate_balance(public_key, blockchain::Blockchain)
   #calculate the balance of a public_key and its related address on the blockchain, return a float amount
   public_key = public_key
   youraddress = ripemd160(string(sha256(string(public_key))))
   youraddress = "0x00"*youraddress
   revenues = []
   expenses = []
   for i in blockchain.chain
      for t in i["transactions"]
         if t["destination"] == public_key
            push!(revenues, t["amount"])
         elseif t["destination"] == youraddress
            push!(revenues, t["amount"])
         elseif t["source"] == public_key   
            push!(expenses, t["amount"])
         end
      end
   end
   if length(revenues) == 0
      return(0)
   elseif length(expenses) == 0
      return(sum(revenues))
   else
      c = (sum(revenues) - sum(expenses))
      return(c)
   end
end


function get_balance(client=nothing, node=nothing)
   if client == nothing
      client = client()
   end
   if node == nothing
      peers = Nodes.discover_peers()
      node = sample(peers, 1)[1]
   end
   return api_client.get_balance(client.public_key, node)
end


function get_transaction_history(client=nothing, node=nothing)
   if client == nothing
      client = client()
   end
   if node == nothing
      peers = Nodes.discover_peers()
      node = sample(peers, 1)[1]
   end
   return api_client.get_transaction_history(client.public_key, node)
end




