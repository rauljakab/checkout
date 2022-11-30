Run Checkout application
- ensure u have elixir installed
- ```mix deps.get && iex -S mix```

Example of use: 
```
Checkout.new() 
Checkout.scan("VOUCHER")
Checkout.scan("TSHIRT")
Checkout.scan("VOUCHER")
Checkout.total()  
```
