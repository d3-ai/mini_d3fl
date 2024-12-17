defmodule MiniD3fl.ComputeNode.AiCoreTest do
  use ExUnit.Case
  use MiniD3fl.Aliases
  def kill_dataloader() do
    case Process.whereis(DataLoader) do
      nil -> nil
      _ -> GenServer.stop(DataLoader, :normal, :infinity)
    end
  end


  test "should train and test for MNIST" do
    kill_dataloader()
    {value, _, _} = MiniD3fl.ComputeNode.AiCore.run(%{}, :mnist, 1, 2, 0.5)
    assert value == :end_train
  end

  @tag timeout: :infinity
  test "should train and test for Cifar10" do
    kill_dataloader()
    {value, _, _} = MiniD3fl.ComputeNode.AiCore.run(%{}, :cifar10, 1, 2, 0.5)
    assert value == :end_train
  end
end
