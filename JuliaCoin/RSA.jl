

#Use it for StringVector
using WeakRefStrings

struct RSA1024
    publicKey::Array{BigInt}
    privateKey::Array{BigInt}
    k::BigInt
    l::BigInt        
    RSA1024() = begin
        local keys = generatekeys()
        local publicKey::Array{BigInt} 
        local privateKey::Array{BigInt} 
        local k = BigInt(0)
        local l = BigInt(0)
        publicKey = [keys[1],keys[2]]
        privateKey = [keys[3],keys[4]]
        k =  Int(ceil(log(BigInt(255),publicKey[1]))) - 2
        l =  Int(ceil(log(BigInt(255),publicKey[1]))) + 2
        new(publicKey, privateKey, k, l)
    end 
end


struct PublicRSA1024
    publicKey::Array{BigInt}
    k::BigInt
    l::BigInt
    PublicRSA1024(rsa)=begin
        if typeof(rsa) == RSA1024
           new(rsa.publicKey,rsa.k,rsa.l)
        else
           new(rsa)
        end
    end
end

struct PrivRSA1024
    privateKey::Array{BigInt}
    k::BigInt
    l::BigInt
    PrivRSA1024(rsa)=begin
        if typeof(rsa) == RSA1024
           new(rsa.privateKey,rsa.k,rsa.l)
        else
           new(rsa)
        end
    end
end

function generatekeys()
    p = gordonalgorithm(1024)
    q = gordonalgorithm(1024)
    while gcd(p-1,q-1) > 3 && abs(length(digits(p))-length(digits(q))) < 5  
        p = gordonalgorithm(1024)
        q = gordonalgorithm(1024)
    end
    na = p * q
    fi = (p - 1)*(q - 1)
    ea = rand(1:fi)
    while gcd(ea,fi) != 1
        ea = rand(1:fi)
    end
    da = invmod(ea,fi)
    return [[na,ea];[na,da]]
end

function encrypt(buf::Union{String, IOStream, Array{UInt8}}, publicRSA::PublicRSA1024) 
    databuffer = Array{UInt8}()
    if typeof(buf)<:IOStream
        databuffer = readall(buf)
        close(buf)
    else
        databuffer = buf
    end
    blockCount = div(length(databuffer), publicRSA.k) + 1
    bufarray = Array{UInt8}(publicRSA.k)
    encryptedtext = Array{UInt8}(0)
    encryptedblocks = Array{BigInt}(0)
    for cnt1 in 1:blockCount
        if cnt1*publicRSA.k < length(databuffer)
            bufarray = Array{UInt8}(databuffer[ ((cnt1-1)* publicRSA.k)+1 : cnt1*publicRSA.k])
        else
            bufarray = Array{UInt8}(databuffer[ ((cnt1-1)* publicRSA.k)+1 : end ])
            append!(bufarray,[length(databuffer);Array{UInt8}(rand(47:255, publicRSA.k-length(bufarray)-2));length(databuffer)])
        end
        m=calcm(bufarray,  publicRSA.k)
        push!(encryptedblocks,powermod(m,publicRSA.publicKey[2],publicRSA.publicKey[1]))
    end
    for cnt3 in 1:length(encryptedblocks)
        letterset = encryptedblocks[cnt3]
        append!(encryptedtext,getletters(letterset,publicRSA.l))
    end
    return encryptedtext
end

function decrypt(buf::Array{UInt8}, privRSA::PrivRSA1024)
    blockCount = div(length(buf), privRSA.l)
    decblocks = Array{BigInt}(0)
    for cnt1 in 1:blockCount
        decblock = buf[(cnt1-1)*privRSA.l+1 : cnt1*privRSA.l]
        m = calcm(decblock, privRSA.l)
        push!(decblocks,powermod(m,privRSA.privateKey[2],privRSA.privateKey[1]))
    end
    decryptedtext = Array{UInt8}(0)
    for cnt3 in 1:length(decblocks)
        letterset = decblocks[cnt3]
        append!(decryptedtext,getletters(letterset,privRSA.k))
    end
    decryptedtext = removepadding!(decryptedtext)
    return decryptedtext
end

function getletters(num::BigInt, len::BigInt)
    letters = Array{UInt8}(0)
    temp = num
    for cnt in 1:len
        letter = UInt8(div(temp,(255^(len-cnt))))
        temp -= BigInt(letter)*(255^(len-cnt))
        push!(letters, letter)
    end
    return letters
end

function signature(message::Union{Array{UInt8},String}, privRSA::PrivRSA1024)
    m = calcm(Array{UInt8}(message), BigInt(length(message)))
    h = hash(m)
    s = h % privRSA.privateKey[1]
    return powermod(s,privRSA.privateKey[2],privRSA.privateKey[1])
end

function verifysign(message::Union{Array{UInt8},String}, signa::BigInt, publicRSA::PublicRSA1024)
    m = calcm(Array{UInt8}(message), BigInt(length(message)))
    w = powermod(signa,publicRSA.publicKey[2],publicRSA.publicKey[1])
    v = hash(m) % publicRSA.publicKey[1]
    return v == w
end

function calcm(arr::Array{UInt8}, len::BigInt)
    m = BigInt(0)
    for cnt in 1:length(arr)
        m+= BigInt(arr[cnt])*(255^(len-cnt))
    end
    return m
end

function removepadding!(arr::Array{UInt8})
    bufferlength = arr[end]
    startPadding = findprev(arr,bufferlength,length(arr)-1)
    if(startPadding >= length(arr) || startPadding == 0)
        return arr
    elseif findfirst(arr[startPadding+1:end-1],bufferlength) == 0 && (bufferlength == arr[startPadding])
        return arr[1:startPadding-1]
    end
    return arr
end




#########RANDOM GENERATOR############

function bin(x::Int, pad::Int, neg::Bool)
    i = neg + max(pad,sizeof(x)<<3-leading_zeros(x))
    a = StringVector(i)
    while i > neg
        a[i] = '0'+(x&0x1)
        x >>= 1
        i -= 1
    end
    if neg; a[1]='-'; end
    String(a)
end



function randombitsnumber(source::Number)
   local len::Number = length(string(source,base=2))
   if len > 3
      return rand((BigInt(1)<<(len-2)):(BigInt(1)<<len))
   end
   return rand(1:BigInt(1)<<len)
end

randomnumber(source::Number) = randombitsnumber(source)

function randomprimenumber(source::Number)
    local x::BigInt
    x = randombitsnumber(source)
    while !millerRabin(x)
        x = randombitsnumber(source)
    end
    return x
end

#strong prime number generator
function gordonalgorithm(bits::Number=512)
    local value::BigInt = BigInt(1)<<div(bits,2)
    local s::BigInt = randomprimenumber(value)
    local t::BigInt = randomprimenumber(value)
    
    local i0::BigInt = rand(3:13)
    while !millerRabin((2*i0*t)+1)
        i0 += 1
    end
    local r::BigInt = (2*i0*t)+1
    
    local p0::BigInt = 2*powermod(s,r-2,r)*s-1
    
    local j0::BigInt = rand(3:13)
    while !millerRabin(p0+2*j0*r*s)
        j0 += 1
    end
    return p0+2*j0*r*s
end


########MILLER RABIN######
function millerRabin(n::BigInt, k::Int = Int(5) )
    # true if strong prime, false if composite   
   if n <= 3
      return false
   elseif n > 3  
      d = n - 1
       r = 0   
       while d % 2 == 0
          r += 1 
          d = div(d, 2)
       end        
       for i in 1:k
          nextLoop = false
          a = rand( 2:(n-2) ) 
          x = powermod(a, d, n)        
          if x == 1 || x == n - 1
             continue
          end       
          for j in 1:(r-1)
             x = powermod(x, 2, n)      
             if x == 1
                return false
             end           
             if x == n - 1
                nextLoop = true
                break
             end           
          end   
          if nextLoop
             continue
          end   
          return false    
   end
   return true
end
end


function isprime(n::Integer)
    n == 2 && return true
    (n < 2) | iseven(n) && return false
    s = trailing_zeros(n-1)
    d = (n-1) >>> s
    for a in witnesses(n)
        a < n || break
        x = powermod(a,d,n)
        x == 1 && continue
        t = s
        while x != n-1
            (t-=1) <= 0 && return false
            x = oftype(n, Base.widemul(x,x) % n)
            x == 1 && return false
        end
    end
    return true
end


