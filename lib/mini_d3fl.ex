defmodule MiniD3fl do
  use ExUnit.Case
  @moduledoc """
  Documentation for `MiniD3fl`.
  """

  test "should deal with stucked model to the same cn" do

    #例えば、
    #CN1 <-[]-> CN2
    #において、それぞれが、モデルを頻繁に送るために、モデルがスタックする場合。
    #チャンネルでモデルの上書きがない＆チャンネル容量を超えるとなくなる＆順にCN2などが更新される
    #を確認したい。

    assert false
  end
end
