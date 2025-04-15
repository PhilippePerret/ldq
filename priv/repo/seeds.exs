# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LdQ.Repo.insert!(%LdQ.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


alias LdQ.Repo
alias LdQ.Comptes.User

hashed_password = Bcrypt.hash_pwd_salt("xadcaX-huvdo9-xidkun")

Repo.insert!(%User{
  name: "Phil", 
  email: "philippe.perret@yahoo.fr",
  hashed_password: hashed_password,
  privileges: 64
})