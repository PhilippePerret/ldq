defmodule Feature.UserTestMethods do
  use ExUnit.Case

  import LdQ.Comptes.User, only: [has_bit?: 2]

  def has_privileges(user, bit) do
    err_msg = "#{user.name} n'a pas le niveau de privilèges attendu.\n  Expected: #{bit}\n  Actual: #{user.privileges}"
    assert(has_bit?(user, bit), err_msg)
    user
  end
  def has_not_privileges(user, bit) do
    err_msg = "#{user.name} ne devrait pas avoir le niveau de privilèges #{bit}.\n  Actual: #{user.privileges}"
    refute(has_bit?(user, bit), err_msg)
    user
  end
  
end