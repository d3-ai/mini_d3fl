defmodule MiniD3fl.ComputeNode.AiCoreTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  test "should train and test for MNIST" do
    {value, _, _} = MiniD3fl.ComputeNode.AiCore.run(%{}, :mnist, 1, 2, 0.5)
    assert value == :end_train
  end
end
