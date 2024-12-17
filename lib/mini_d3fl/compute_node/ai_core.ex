defmodule MiniD3fl.ComputeNode.AiCore do
  use GenServer
  alias Mnist
  alias Cifar10

  def init(init_arg) do
    {:ok, init_arg}
  end

  def run(former_model \\ %{}, data_name, client_id, client_num, sample_rate) do
    case data_name do
      :mnist -> Mnist.run(former_model, client_id, client_num, sample_rate)
      :cifar10 -> Cifar10.run(former_model, client_id, client_num, sample_rate)
    end
  end
  def data_download(:mnist, client_num, sample_rate) do
    Mnist.data_download(:mnist, client_num, sample_rate)
  end

  def data_download(:cifar10, client_num, sample_rate) do
    Cifar10.data_download(:cifar10, client_num, sample_rate)
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
