#https://juliadocs.github.io/Documenter.jl/stable/man/hosting/walkthrough/index.html



shell>ssh-keygen -N "" -f privatekey

using Base64

read("privatekey", String) |> base64encode |> println

read("privatekey.pub", String) |> println

