


struct miner
   Server::String
   PublicKey::Array
   miner(Server, PublicKey) = begin
      Server = Server
      PublicKey = PublicKey
      new(Server, PublicKey)
   end
end



struct pool
   minerslist::Array
   nminers::Int64
   totreward::Int64
   rewardmin::Float64
   pool(minerslist,totreward) = begin
      minerslist = minerslist
      totreward = totreward
      nminers = length(minerslist)
      rewardmin = totreward/nminers
      pool(minerslist,nminers,totreward,rewardmin)
   end
end


function payminer(miner, reward)
   address = miner.PublicKey
   coinbasegenesistransaction(miner.PublicKey, juliablockchain, reward)
end



function payminersinpool(pool)
   global juliablockchain   
   for miner in pool.minerslist
      reward = pool.rewardmin
      coinbasegenesistransaction(miner.PublicKey, "1", juliablockchain, reward)
   end
end
