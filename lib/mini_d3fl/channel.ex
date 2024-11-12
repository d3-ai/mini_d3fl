defmodule MiniD3fl.Channel do
  use GenServer
  alias MiniD3fl.Utils
  alias MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.Model

  defmodule QoS do
    defstruct bandwidth: nil,
              packetloss: 0,
              capacity: nil
  end

  defmodule State do
    defstruct channel_id: 0,
              from_cn_id: nil,
              to_cn_id: nil,
              queue: nil,
              model_sum_size: 0,
              QoS: %QoS{}
  end

  defmodule InitArgs do
    defstruct channel_id: 0,
              from_cn_id: nil,
              to_cn_id: nil,
              QoS: %QoS{}
  end

  def start_link(%InitArgs{} = args) do
    {:ok, channel_pid}
    = GenServer.start_link(
      __MODULE__,
      args)
    IO.puts "channel_pid is"
    IO.inspect channel_pid
    {:ok, channel_pid}
  end

  def init(%InitArgs{
    channel_id: channel_id,
    from_cn_id: from_cn_id,
    to_cn_id: to_cn_id,
    QoS: qos
  } = _args) do
    queue = :queue.new
    {
      :ok, %State{
        channel_id: channel_id,
        from_cn_id: from_cn_id,
        to_cn_id: to_cn_id,
        queue: queue,
        model_sum_size: 0,
        QoS: qos
      }
    }
  end

  def recv_model_at_channel(channel_pid, model) do
    GenServer.call(
      channel_pid,
      {:recv_model_at_channel, model}
    )
  end

  def send_model_from_channel(channel_pid) do
    GenServer.call(
      channel_pid,
      {:send_model_from_channel}
    )
  end

  def get_state(channel_pid) do
    GenServer.call(
      channel_pid,
      {:get_state})
  end

  def handle_call({:recv_model_at_channel,
                    %Model{size: model_size, plain_model: plain_model} = model},
                  _from,
                  %State{ channel_id: channel_id,
                          from_cn_id: from_cn_id,
                          to_cn_id: to_cn_id,
                          queue: queue,
                          model_sum_size: sum_size,
                          QoS: %QoS{
                            bandwidth: bandwidth,
                            packetloss: packetloss,
                            capacity: capacity
                          }} = state) do
    cond do
      sum_size + model_size > capacity ->
        IO.puts "At Channel #{channel_id} : model over rest of capacity"
        {:reply, {:warning, "over_the_limit"}, state}
      is_loss_packet(packetloss) ->
        {:reply, {:warning, "paket loss"}, state}
      true ->
        #TODO: このときに、EventQueueにmodel_size/bandwidth秒後のresv_model_cnイベントを追加
        {:reply, :ok, %State{
          state| queue: :queue.in(model, queue), model_sum_size: sum_size + model_size}}
    end
  end

  def handle_call({:send_model_from_channel},
                  _from,
                  %State{ channel_id: channel_id,
                          from_cn_id: from_cn_id,
                          to_cn_id: to_cn_id,
                          queue: queue,
                          model_sum_size: sum_size,
                          QoS: %QoS{
                            bandwidth: bandwidth,
                            packetloss: packetloss,
                            capacity: capacity
                          }} = state) do

    {{:value, head_model}, new_queue} = :queue.out(queue)
    %Model{size: head_model_size} = head_model
    if ComputeNode.is_available(to_cn_id) do
      ComputeNode.recv_model(%ComputeNode.RecvArgs{
        from_node_id: from_cn_id,
        to_node_id: to_cn_id,
        model: head_model
      })
    else
      IO.puts "ComputeNode #{to_cn_id} is unavailable"
    end

    {:reply, :ok, %State{state | queue: new_queue, model_sum_size: sum_size - head_model_size}}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def is_loss_packet(packetloss) do
    random_number = :rand.uniform()
    if random_number <= packetloss do
      true
    else
      false
    end
  end
end
