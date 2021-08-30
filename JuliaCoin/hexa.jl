

function hexa(x::UInt32)
    i = 1 + (sizeof(x)<<1)-(leading_zeros(x)>>2)
    a = []
    while i > 1
        d = x & 0xf
        push!(a,'0'+d+39*(d>9))
        x >>= 4
        i -= 1
    end
    push!(a,'-');
    c = ""
    for i in length(a):-1:1
       c = c*a[i]
    end
    return c
end


#Revoir num2hex
num2hex(n::Integer) = hexa(n, sizeof(n)*2)
















