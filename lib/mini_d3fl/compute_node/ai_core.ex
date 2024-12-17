defmodule MiniD3fl.ComputeNode.AiCore do
  use GenServer
  alias Mnist

  def init(init_arg) do
    {:ok, init_arg}
  end

  def run(former_model \\ %{}, client_id, client_num, sample_rate) when is_integer(client_id) do
    Mnist.run(former_model, client_id, client_num, sample_rate)
  end

  def data_download(:mnist, client_num, sample_rate) do
    Mnist.data_download(:mnist, client_num, sample_rate)
  end

  def aggregate(map_a, %{}, _rate_b) do
    map_a
  end

  def aggregate(%{}, map_b, _rate_b) do
    map_b
  end

  def aggregate(map_a, map_b, rate_b) do
    keys = Map.keys(map_a)
    result_map = %{}
    [result_map] = Enum.map(keys, fn key ->
      value_a = Map.get(map_a, key)
      v_a_bias = Map.get(value_a, "bias")
      v_a_kernel = Map.get(value_a, "kernel")

      value_b = Map.get(map_b, key)
      v_b_bias = Map.get(value_b, "bias")
      v_b_kernel = Map.get(value_b, "kernel")

      result_map = Map.put(
        result_map,
        key,
        %{"bias" => Nx.multiply(v_b_bias, rate_b)
                    |> Nx.add(v_a_bias)
                    |> Nx.divide(1 + rate_b),
          "kernel" => Nx.multiply(v_b_kernel, rate_b)
                    |> Nx.add(v_a_kernel)
                    |> Nx.divide(1 + rate_b)}
      )
      result_map
    end)
    result_map
  end
end
