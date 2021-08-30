using HTTP, Random, Bukdu, UUIDs, Dates, JSON, Sockets


struct CryptoController <: ApplicationController
    conn::Conn
end

function addtransaction(c::CryptoController)
   req = c.conn.request
   responsar = Dict(req.headers)
   Enfin = responsar["Enfin"]
   return Enfin
end

routes() do
    post("/addtransaction", CryptoController, addtransaction)
end

Bukdu.start(8080, host = "127.0.0.1")

x = Dict("Enfin" => 22)

HTTP.request("POST","http://127.0.0.1:8080/addtransaction", x)
