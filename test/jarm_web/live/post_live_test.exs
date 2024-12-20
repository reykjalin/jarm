defmodule JarmWeb.PostLiveTest do
  use JarmWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Jarm.Timeline

  @create_attrs %{body: "some body", user: "some user"}
  @update_attrs %{body: "some updated body", user: "some updated user"}
  @invalid_attrs %{body: nil, user: nil}

  defp fixture(:post) do
    {:ok, post} = Timeline.create_post(@create_attrs)
    post
  end

  defp create_post(_) do
    post = fixture(:post)
    %{post: post}
  end

  describe "Index" do
    setup [:create_post]

    test "lists all posts", %{conn: conn, post: post} do
      {:ok, _index_live, html} = live(conn, ~p"/#{conn.params["locale"]}")

      assert html =~ "Listing Posts"
      assert html =~ post.body
    end

    test "saves new post", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/#{conn.params["locale"]}")

      assert index_live |> element("a", "New Post") |> render_click() =~
               "New Post"

      assert_patch(index_live, ~p"/#{conn.params["locale"]}")

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#post-form", post: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/#{conn.params["locale"]}")

      assert html =~ "Post created successfully"
      assert html =~ "some body"
    end

    test "updates post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/#{conn.params["locale"]}")

      assert index_live |> element("#post-#{post.id} a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(index_live, ~p"/#{conn.params["locale"]}")

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#post-form", post: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/#{conn.params["locale"]}")

      assert html =~ "Post updated successfully"
      assert html =~ "some updated body"
    end

    test "deletes post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/#{conn.params["locale"]}")

      assert index_live |> element("#post-#{post.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#post-#{post.id}")
    end
  end

  describe "Show" do
    setup [:create_post]

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/#{conn.params["locale"]}/posts/#{post.id}")

      assert html =~ "Show Post"
      assert html =~ post.body
    end

    test "updates post within modal", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/#{conn.params["locale"]}/posts/#{post.id}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(show_live, ~p"/#{conn.params["locale"]}/posts/#{post.id}/edit")

      assert show_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#post-form", post: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/#{conn.params["locale"]}/posts/#{post.id}")

      assert html =~ "Post updated successfully"
      assert html =~ "some updated body"
    end
  end
end
