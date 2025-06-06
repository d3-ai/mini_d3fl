defmodule MiniD3fl.Channel do
  use GenServer
  alias MiniD3fl.Utils
  alias MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.Model
  alias MiniD3fl.JobController
  alias MiniD3fl.JobController.EventQueue.Event

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
              latest_model_sent_time: nil,
              model_sum_size: 0,
              QoS: %QoS{}
  end

  defmodule ChannelArgs do
    @moduledoc """
    from_cn_id: int,
    to_cn_id: int,
    QoS: %QoS{}
    """
    defstruct from_cn_id: nil,
              to_cn_id: nil,
              QoS: %QoS{}
  end

  def start_link(
    %ChannelArgs{from_cn_id: from_id, to_cn_id: to_id} = args) do
    {:ok, channel_pid}
    = GenServer.start_link(
      __MODULE__,
      args,
      name: Utils.get_channel_name(from_id, to_id))
    {:ok, channel_pid}
  end

  def init(%ChannelArgs{
    from_cn_id: from_cn_id,
    to_cn_id: to_cn_id,
    QoS: qos
  } = _args) do
    queue = :queue.new
    {
      :ok, %State{
        from_cn_id: from_cn_id,
        to_cn_id: to_cn_id,
        queue: queue,
        model_sum_size: 0,
        QoS: qos
      }
    }
  end

  def change_channel_params(%ChannelArgs{from_cn_id: fid, to_cn_id: tid} = args) do
    case Process.whereis(Utils.get_channel_name(fid, tid)) do
      nil ->
        IO.puts "new channel from #{fid} to #{tid}"
        MiniD3fl.Channel.start_link(args)

      _ ->
        GenServer.call(
          Utils.get_channel_name(fid, tid),
          {:change_channel_params, args}
        )
    end
  end

  def recv_model_at_channel(from_id, to_id, model, now_time) do
    GenServer.call(
      Utils.get_channel_name(from_id, to_id),
      {:recv_model_at_channel, now_time, model}
    )
    #TODO: JobController IDの共有
  end

  def send_model_from_channel(fid, tid, time) do
    GenServer.call(
      Utils.get_channel_name(fid, tid),
      {:send_model_from_channel, time}
    )
  end

  def get_state(from_id, to_id) do
    GenServer.call(
      Utils.get_channel_name(from_id, to_id),
      {:get_state})
  end

  def handle_call({:change_channel_params, %ChannelArgs{QoS: qos} = _args},
                  _from,
                  state) do
    IO.puts "change channel params"
    {:reply, :ok, %State{state | QoS: qos}}
  end

  def handle_call({:recv_model_at_channel, now_time,
                    %Model{size: model_size, plain_model: _plain_model} = model},
                  _from,
                  %State{ channel_id: channel_id,
                          from_cn_id: from_cn_id,
                          to_cn_id: to_cn_id,
                          queue: queue,
                          model_sum_size: sum_size,
                          latest_model_sent_time: sent_time,
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
        IO.puts "At Channel from #{from_cn_id} to #{to_cn_id}: packet loss"
        {:reply, {:warning, "paket loss"}, state}
      true ->
        {recv_time, new_sent_time} = case sent_time do
          nil ->
            {now_time + (sum_size + model_size) / bandwidth, now_time}
          _ ->
            {now_time + (sum_size + model_size) / bandwidth - (now_time - sent_time), sent_time}
        end

        # TODO: controllerのidの指定
        job_controller_id = 0
        event = %Event{time: recv_time, event_name: :recv, args: %{from_id: from_cn_id, to_id: to_cn_id}}

        GenServer.call(
          Utils.get_process_name(JobController, job_controller_id),
          {:add_event, event}
        )

        {:reply, :ok, %State{
          state| queue: :queue.in(model, queue), model_sum_size: sum_size + model_size, latest_model_sent_time: new_sent_time}}
    end

  end

  def handle_call({:send_model_from_channel, time},
                  _from,
                  %State{ channel_id: _channel_id,
                          from_cn_id: from_cn_id,
                          to_cn_id: to_cn_id,
                          queue: queue,
                          model_sum_size: sum_size,
                          QoS: %QoS{
                            bandwidth: _bandwidth,
                            packetloss: _packetloss,
                            capacity: _capacity
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

    new_model_sum_size = sum_size - head_model_size

    latest_model_time = if new_model_sum_size == 0 do
      nil
    else
      time
    end
    {:reply, :ok, %State{state | queue: new_queue, model_sum_size: new_model_sum_size, latest_model_sent_time: latest_model_time}}
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
