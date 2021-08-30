include("jcoinapp.jl")


#Create blockchain, user and miner
juliablockchain = Blockchain()

choosekeys(actualuser,1)

clientadresse = actualuser.clientlist[2].public_key

actualminer = miner(hostip*":"*string(jcoinport), clientadresse)



#Create coinbase transaction and first block of blockchain

coinbasegenesistransaction(actualminer.PublicKey, juliablockchain)


firstdifficulty = "000000"

create_block(juliablockchain, 0, "0", firstdifficulty)


HTTP.request("POST", connectnode)



#Create loop for transaction creation and mining

nodeconnected = true

while nodeconnected == true

# first transaction
   choosekeys(actualuser,2)

   clientadresse = actualuser.clientlist[3].public_key
	
   create_transaction(juliablockchain, yourpublickey, clientadresse, yourprivatekey, 100, 1.85, "2")

   HTTP.request("GET", miningblock)

#second transaction
   choosekeys(actualuser,3)

   clientadresse = actualuser.clientlist[2].public_key

   create_transaction(juliablockchain, yourpublickey, clientadresse, yourprivatekey, 25, 0.87, "2")

   HTTP.request("GET", miningblock) 
   HTTP.request("GET", replacechain)
end 



