defmodule ChangePklTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  test "should make packetloss change queue" do
    node_num = 2

    queue = Enum.reduce(1..node_num, EventQueue.init_queue(), fn from, from_queue ->
      Enum.reduce(1..node_num, from_queue, fn to, to_queue ->
        to_queue
        |> EventQueue.insert_command(%Event{
          time: 1,
          event_name: :change_channel_params,
          args: %ChannelArgs{
            from_cn_id: from,
            to_cn_id: to,
            QoS: %QoS{
              bandwidth: 100,
              packetloss: (if from == to, do: 1, else: 0),
              capacity: 10000
            }
          }
        })
      end)
    end )

    IO.inspect queue
  end
end
