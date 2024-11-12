defmodule MiniD3fl.Utils do
  def get_process_name(module, index) do
    # JobController と ComputerNodeにのみ使う。
    # Channelには使わない。
    # これで、並列の理論的限界は100,00,00程度。
    :"#{module}_#{index}"
  end

end
