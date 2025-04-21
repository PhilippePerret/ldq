defmodule LdQ.SiteFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Site` context.
  """

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        published_at: ~N[2025-04-13 06:02:00],
        slug: "some slug",
        status: 42,
        template: "some template"
      })
      |> LdQ.Site.create_page()

    page
  end

  @doc """
  Generate a page_locale.
  """
  def page_locale_fixture(attrs \\ %{}) do
    {:ok, page_locale} =
      attrs
      |> Enum.into(%{
        content: "some content",
        image: "some image",
        locale: "some locale",
        meta_description: "some meta_description",
        meta_title: "some meta_title",
        raw_content: "some raw_content",
        status: 42,
        summary: "some summary",
        title: "some title"
      })
      |> LdQ.Site.create_page_locale()

    page_locale
  end
end
