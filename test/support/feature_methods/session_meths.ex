defmodule Feature.SessionMethods do


  # Comme on peut envoyer indifféremment aux fonctions l'user ou
  # la session, on doit traiter session pour en avoir vraiment une
  # 
  # 
  # 
  @doc """
  Donc mettre en début de toutes les méthodes :

    def mafonction(session, ...) do
      session = session_from(session)
  """
  def session_from(session) do
    if Map.has_key?(session, :session) do
      session.session # quand user
    else
      session
    end
  end


end