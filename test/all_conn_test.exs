defmodule AllConnTest do
  use ExUnit.Case
  use MiniD3fl.Aliases


  defp assert_queue_contents(queue1, queue2) do
    case {EventQueue.pop_command(queue1), EventQueue.pop_command(queue2)} do
      {{:ok, event1, new_queue1}, {:ok, event2, new_queue2}} ->
        assert assert event1 == event2
        IO.inspect event1
        assert_queue_contents(new_queue1, new_queue2)

      {{:empty, _, _}, {:empty, _, _}} ->
        # 両方のキューが空なら成功
        :ok

      _ ->
        flunk("The queues have different contents or lengths")
    end
  end

  test "should make event queue for all connect" do
    init_queue = EventQueue.init_queue()
    queue = AllConn.setup_queue_num(init_queue, 1, 3, 1)

    IO.inspect queue
    IO.puts "==========================="


    correct_queue =
      init_queue
      |> EventQueue.insert_command(%Event{
        time: 10,
        event_name: :send,
        args: %SendArgs{
          from_node_id: 1,
          to_node_id: 1,
          time: 10
        }
      })
      |> EventQueue.insert_command(%Event{
        time: 10,
        event_name: :send,
        args: %SendArgs{
          from_node_id: 1,
          to_node_id: 2,
          time: 10
        }
      })
      |> EventQueue.insert_command(%Event{
        time: 10,
        event_name: :send,
        args: %SendArgs{
          from_node_id: 1,
          to_node_id: 3,
          time: 10
        }
      })
      |> EventQueue.insert_command(%Event{
        time: 5,
        event_name: :train,
        args: %TrainArgs{node_id: 1}
      })
      |> EventQueue.insert_command(%Event{
        time: 15,
        event_name: :train,
        args: %TrainArgs{node_id: 1}
      })
    IO.inspect correct_queue
    IO.puts "++++++++++++++++++"
    assert_queue_contents(correct_queue, queue)
  end

end
