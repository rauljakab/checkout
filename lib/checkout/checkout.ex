defmodule Checkout do
  use Agent
  alias Poison

  def new() do
    # we are storing the list of checkout products in state
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def total do
    prices = get_json("lib/checkout/pricing.json")

    Agent.get(__MODULE__, & &1)
    |> compute_total_price(prices)
  end

  def scan(item) do
    Agent.update(__MODULE__, &(&1 ++ [item]))
  end

  def compute_total_price(items, price) do
    # I decided to go here with a list of frequencies for products because in this way will be easier to apply the discount and in this way we will read the list of items just once
    items_count = items |> Enum.frequencies()

    hugs_price = (items_count["MUG"] || 0) * price["MUG"]
    tshirts_price = (items_count["TSHIRT"] || 0) * price["TSHIRT"]
    vouchers_price = (items_count["VOUCHER"] || 0) * price["VOUCHER"]

    total = hugs_price + tshirts_price + vouchers_price
    total_discount = discounts(items_count, price)

    (total - total_discount)
    |> format_result()
  end

  def get_json(filename) do
    # read pricing data from the configurable json
    with {:ok, body} <- File.read(filename), {:ok, json} <- Poison.decode(body), do: json
  end

  def discounts(items_count, prices) do
    # list of discounts that will be applied on total price
    # discounts will be applied in order
    [
      tshirt_discount(items_count["TSHIRT"]),
      voucher_discount(items_count["VOUCHER"], prices["VOUCHER"])
    ]
    |> Enum.sum()
  end

  defp tshirt_discount(tshirt_count) do
    # compute tshirt discount
    # if 3 or more tshits price will be with 1€ lower per item(20€ -> 19€)
    if tshirt_count && tshirt_count > 2 do
      tshirt_count
    else
      0
    end
  end

  defp voucher_discount(voucher_count, voucher_price) do
    # compute voucher discount
    # 2 for 1 discount ( at every second voucher price will drop with the voucher price)
    if voucher_count && voucher_count > 1 do
      div(voucher_count, 2) * voucher_price
    else
      0
    end
  end

  defp format_result(result) do
    # 
    # show 2 decimals for the price followed by currency( € )
    price = :erlang.float_to_binary(result, decimals: 2)
    "#{price}€"
  end
end
