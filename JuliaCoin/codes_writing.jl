include("Wallet.jl")


function write_codes()
   codes = input("Please input your code here: ")
   try
      eval(Meta.parse(codes))
      return codes
   catch
      return false
   end
end

