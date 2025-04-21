defmodule LdQ.Constantes do

  def get(constant_id) do
    case constant_id do
      :app_url ->
        case Application.get_env(:ldq, :env) do
          :dev  -> "http://localhost"
          :prod -> "https://www.label-de-qualite"
          :test -> ""
        end
    end
  end
end