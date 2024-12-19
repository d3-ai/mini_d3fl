defmodule MiniD3fl.ComputeNode.AiCore.Aggregate.FedavgTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  test "should do fedavg in sample models" do
    maps = [
      %{"a" => %{"bias" => Nx.tensor([3.0]), "kernel" => Nx.tensor([3.0])}, "b" => %{"bias" => Nx.tensor([3.0]), "kernel" => Nx.tensor([3.0])}},
      %{"a" => %{"bias" => Nx.tensor([4.0]), "kernel" => Nx.tensor([4.0])}, "b" => %{"bias" => Nx.tensor([4.0]), "kernel" => Nx.tensor([4.0])}},
      %{"a" => %{"bias" => Nx.tensor([5.0]), "kernel" => Nx.tensor([5.0])}, "b" => %{"bias" => Nx.tensor([5.0]), "kernel" => Nx.tensor([5.0])}},
    ]

    avg_map = FedAvg.average(maps)

    assert avg_map == %{"a" => %{"bias" => Nx.tensor([4.0]), "kernel" => Nx.tensor([4.0])}, "b" => %{"bias" => Nx.tensor([4.0]), "kernel" => Nx.tensor([4.0])}}

  end

  test "should do fedavg in sample models with %{}" do
    maps = [
      %{},
      %{"a" => %{"bias" => Nx.tensor([4.0]), "kernel" => Nx.tensor([4.0])}, "b" => %{"bias" => Nx.tensor([4.0]), "kernel" => Nx.tensor([4.0])}},
      %{"a" => %{"bias" => Nx.tensor([5.0]), "kernel" => Nx.tensor([5.0])}, "b" => %{"bias" => Nx.tensor([5.0]), "kernel" => Nx.tensor([5.0])}},
    ]

    avg_map = FedAvg.average(maps)

    assert avg_map == %{"a" => %{"bias" => Nx.tensor([4.5]), "kernel" => Nx.tensor([4.5])}, "b" => %{"bias" => Nx.tensor([4.5]), "kernel" => Nx.tensor([4.5])}}

  end

  test "should do fedavg in real models" do
    {_, model1, _} = Mnist.run(%{}, 1, 3, 0.01)
    {_, model2, _} = Mnist.run(%{}, 2, 3, 0.01)
    {_, model3, _} = Mnist.run(%{}, 3, 3, 0.01)


    IO.inspect FedAvg.average([model1, model2, model3])
  end

end
