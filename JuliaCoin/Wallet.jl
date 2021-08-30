
using SHA, JSON

include("Client.jl")

mutable struct wallet
   #=
      Create an object of structure Wallet: This class allows a user to create a wallet that will store the data for specific users
   
       Attributes
       ----------
       usernamelist : array
           the list of users objects belonging to that wallet
       actualuser : user
           the user object that is currently connected
       userconnected : bool
           A bool variable that tells us if a user is connected or not
   
      Example:
         Wallet1 = wallet()
   =#
   usernamelist::Array
   userconnected::Bool
   wallet() = begin
      usernamelist = []
      userconnected = false
   new(usernamelist,userconnected)
   end
end

mutable struct user
   """   
       Create an object of structure user: This class store the data of a user such as his user name, password and the clientlist
   
        Parameters
        ----------
        username : string
            The name of the user to be created
        clientlist : array, optional, default empty array
            The list of client accounts (address, private key, public key) that belong to that user and can be used by him.
        password : string, optional, default None
            The password of the user that will be used to determine if this is the user connecting to his account.
   
        Attributes
        ----------
        username : string
            the name of the user
        clientlist : array
            the array containing each client objects that belongs to the user. A client object include address, private key and public key.
        password : string
            the password of the user
   
       Example:
          user("julius")
          user("julius", password = password)
          user("julius", accountlist, password)
   """
   username::String
   clientlist::Array
   password::Array
   user(username,clientlist=[],password=[]) = begin
      username = username
      clientlist = clientlist
      if password == []
         password = sha256(input("Please create user password: "))
      else
         password = password
      end
   new(username,clientlist,password)
   end
end 


localwallet = wallet()


#Create username and password
function createuser(localwallet::wallet)
   if localwallet.userconnected == true
      print("You are already connected under a user name; you must be disconnected to create a new user, please disconnect from the current user and try again")
   else 
      goodusername = false
      liste=[]
      for i in localwallet.usernamelist
          push!(liste,i.username)
      end
      global username, newuser, goodusername
      while goodusername == false   
         username = input("Please create a username: ")
         if username in liste
            print("Username already exists, please choose another username! ")
         else
            goodusername = true
            newuser = user(username)
            break
         end
      end
      push!(localwallet.usernamelist, newuser)
      print("Congrats, you just created a new user and you are now connected under: ", newuser)
      connectuser(localwallet,newuser.username)
   end
end


#Connect user
function connectuser(localwallet::wallet,username=nothing)
   combination = false
   while combination == false
      if username == nothing
         username = input("Please enter a username: ")
      else
          username = username
      end
      password = sha256(input("Please enter your password: "))      
      for users in localwallet.usernamelist
         if username == users.username
            if password == users.password
               global actualuser
               print("Welcome into your account")
               combination = true
               actualuser = users
               localwallet.userconnected = true
            else
               print("Wrong username/password combination please try something else ")
            end
          end
       end
   end
end


#Change password
function changepassword(localwallet::wallet)
   if localwallet.userconnected == true
      password = sha256(input("Please enter your password: "))
      newpassword = sha256(input("Please enter your new password: "))
      newpassword1 = sha256(input("Please confirm your new password: "))
      if newpassword == newpassword1
         actualuser.password = []
         actualuser.password = newpassword
      else
         print("Wrong username/password combination please try something else")
      end
   else
      print("You need to be connected to an account to change your password")
   end
end


#Disconnect user
function disconnectuser(localwallet::wallet)
   global actualuser
   sure = input("Are you sure  you want to disconnect? ")
   if sure == "Yes"
      localwallet.userconnected = false 
      modifiedwallet = json(localwallet)
      close(fali)
      write("localwallet.txt", modifiedwallet)
      actualuser = nothing
   end
end      


#createaddress
function createaddress(localwallet::wallet,actualuser=actualuser)
   if localwallet.userconnected == true
      newclient = client()
      push!(actualuser.clientlist, newclient)
   end
end



#Import file with username
global localwallet
if "localwallet.txt" in readdir()
   fali = open("localwallet.txt")
   data = read(fali)
   data = String(data)
   #No user exist please create one
   if length(data) == 0
      createuser(localwallet)
      actualuser = localwallet.usernamelist[1]
      localwallet.userconnected = true   
      fali = open("localwallet.txt", "w")      
   else
      data = JSON.parse(data,inttype=BigInt)
   #Users exist no need to create one:  
      for users in data["usernamelist"]
         newclientlist = []
         for clientadd in users["clientlist"]
            newadd = client(clientadd["private_key"], clientadd["public_key"], address(clientadd["public_key"]))
            push!(newclientlist,newadd)
         end
         newuser = user(users["username"], newclientlist,users["password"])
         push!(localwallet.usernamelist, newuser)
      end
      connectuser(localwallet)
   end
end


#Choose public private key for transaction
function choosekeys(actualuser,num)
   global yourpublickey, yourprivatekey
   yourpublickey = actualuser.clientlist[num].public_key
   yourprivatekey = actualuser.clientlist[num].private_key
   return yourpublickey, yourprivatekey
end




