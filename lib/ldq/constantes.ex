defmodule LdQ.Constantes do

  @env Application.get_env(:ldq, :env)

  # Pour utiliser :
  #   if Constantes.env == :test
  # ou 
  #   if Constantes.env_test? do
  #     ...
  def env, do: @env
  def env_test?,  do:  @env == :test
  def env_prod?,  do:  @env == :prod
  def env_dev?,   do: @env == :dev

  def get(constant_id) do
    case constant_id do
      :app_url ->
        case Application.get_env(:ldq, :env) do
          :dev  -> "http://localhost"
          :prod -> "https://www.label-de-qualite"
          :test -> ""
        end
      :mail_admin ->
        "admin@lecture-de-qualite.fr"
      :mail_admins -> 
        "admin@lecture-de-qualite.fr"
      :pays_pour_menu ->
        [
          ["France", "fr"],
          ["États-unis", "us"],
          ["Angleterre", "en"],
          ["Allemagne", "de"]
        ]
    end
  end
end