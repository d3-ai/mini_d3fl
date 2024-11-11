defmodule MiniD3fl.JobControllerTest do
  use ExUnit.Case
  doctest MiniD3fl.JobController
  alias MiniD3fl.JobController

  test "should init EventQueue" do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue, 5, :train, %{})
    queue = EventQueue.insert_command(queue, 3, :send, %{})
    queue = EventQueue.insert_command(queue, 7, :train, %{})

  end
end
